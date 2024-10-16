import argparse
import os
import arcpy
import logging
import subprocess
import datetime
import shutil
import boto3
import sys
import pandas as pd
from types import SimpleNamespace
import geopandas as gpd
import pyarrow as pa
import pyarrow.parquet as pq
import fiona
from botocore.exceptions import NoCredentialsError
import etl_scripts.bronze.utils as egis_utils

# from arcgis.features import GeoAccessor, GeoSeriesAccessor
def cleanup_file(paths):
    for path in paths:
        try:
            if os.path.exists(path):
                if os.path.isfile(path):
                    os.remove(path)
                else:
                    shutil.rmtree(path)
                print(f"{path} deleted successfully.")
            else:
                print(f"File {path} does not exist.")
        except Exception as e:
            print(f"{e}")

def create_gdb_zip(gb, o):
    zipFile = f"{o}.7z"
    cleanup_file([zipFile])
    try:
        print(f"creating {zipFile}")
        # subprocess.run([r'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7z', 'a', zipFile, o])
        # Use subprocess.run with check=True to raise an exception on non-zero exit codes
        result = subprocess.run(
            [rf'{gb.configs.zip_path}/7z', 'a', zipFile, o],
            check=True,  # Raises CalledProcessError if the command fails
            stdout=subprocess.PIPE,  # Captures stdout
            stderr=subprocess.PIPE  # Captures stderr
        )
        # print("Archive created successfully:", result.stdout.decode())
        print("Archive created successfully:")
    except subprocess.CalledProcessError as e:
        # Handle command execution error
        print(f"Error occurred while creating archive: {e.stderr.decode()}")
        print(f"Return code: {e.returncode}")
    except FileNotFoundError:
        # Handle case where 7z is not found
        print("7z executable not found. Make sure it's installed and in your system PATH.")
    except Exception as e:
        # Handle any other general exceptions
        print(f"An unexpected error occurred: {e}")

    return zipFile

def upload_directory_to_s3(gb, directory_path, s3_prefix=''):
    # aws s3 sync Ice_Jam_database s3://usace-asr/Ice_Jam_Database
    s3_bucket_folder = f"s3://{gb.configs.etl_s3_bucket}/{s3_prefix}"

    try:
        # subprocess.run([r'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7z', 'a', zipFile, o])
        # Use subprocess.run with check=True to raise an exception on non-zero exit codes
        result = subprocess.run(
            ["aws", "s3", "sync", directory_path, s3_bucket_folder],
            check=True,  # Raises CalledProcessError if the command fails
            stdout=subprocess.PIPE,  # Captures stdout
            stderr=subprocess.PIPE  # Captures stderr
        )
        # print("Archive created successfully:", result.stdout.decode())
        gb.logger.info("Data synched to S3 Bucket successfully:")
    except subprocess.CalledProcessError as e:
        # Handle command execution error
        gb.logger.info(f"Error occurred while moving folder to s3 bucket: {e.stderr.decode()}")
        gb.logger.info(f"Return code: {e.returncode}")
    except FileNotFoundError:
        # Handle case where 7z is not found
        gb.logger.info("7z executable not found. Make sure it's installed and in your system PATH.")
    except Exception as e:
        # Handle any other general exceptions
        (gb.logger.info
         (f"An unexpected error occurred: {e}"))
def upload_directory_to_s3_2(bucket_name, directory_path, s3_prefix=''):
    # Initialize the S3 client
    s3_client = boto3.client('s3')
    base_name = os.path.basename(directory_path)

    # Walk through the directory and upload each file
    for root, dirs, files in os.walk(directory_path):
        for filename in files:
            # Construct the full local file path
            local_path = os.path.join(root, filename)

            # Construct the S3 object key by preserving the directory structure
            relative_path = os.path.relpath(local_path, directory_path)
            s3_key = os.path.join(s3_prefix, base_name, relative_path).replace("\\", "/")

            # Upload the file to S3
            try:
                s3_client.upload_file(local_path, bucket_name, s3_key)
                print(f"Uploaded {local_path} to s3://{bucket_name}/{s3_key}")
            except Exception as e:
                print(f"Failed to upload {local_path}: {e}")

def publish_layers(gb):
    # Connect to the SDE database
    sde_connection = gb.sde_connection

    arcpy.env.workspace = sde_connection
    schema = gb.product.schema

    collection_name = gb.product.collection_name.replace(" ","_")
    local_output = os.path.join(gb.configs.output_dir,collection_name)
    feature_classes = arcpy.ListFeatureClasses(f"*.{schema}.*")
    schema_classes = sorted(feature_classes)
    tables = arcpy.ListTables(f"*.{schema}.*")
    table_classes = sorted(tables)

    output_gdb = os.path.join(rf"{local_output}",f"{schema}.gdb")
    gpkg_path = os.path.join(rf"{local_output}",f"{schema}.gpkg")
    if os.path.exists(local_output):
        cleanup_file([output_gdb, gpkg_path])
    else:
        os.makedirs(local_output, exist_ok=True)
    # Create a GeoPackage
    try:
        arcpy.CreateFileGDB_management(local_output,f"{schema}.gdb")
        arcpy.FeatureClassToGeodatabase_conversion(schema_classes + table_classes, output_gdb)
    except Exception as fge:
        print(fge)
    try:
        arcpy.management.CreateSQLiteDatabase(gpkg_path, "GEOPACKAGE")
        arcpy.FeatureClassToGeodatabase_conversion(schema_classes + table_classes, gpkg_path)
    except Exception as ge:
        print(ge)


    # # Export feature classes and tables to the GDB
    geojson_dir = os.path.join(rf"{local_output}", "geojson")
    os.makedirs(geojson_dir, exist_ok=True)
    parquet_dir = os.path.join(f'{local_output}', 'geoparquet')
    os.makedirs(parquet_dir, exist_ok=True)
    layers = fiona.listlayers(output_gdb)
    gdf_list = []
    # Iterate over each layer and convert it to GeoParquet
    first_crs = None
    for layer in layers:
        try:
            # Read the layer into a GeoDataFrame
            gdf = gpd.read_file(output_gdb, layer=layer)
            # Can geopandas be replaced with arcpy spatially enabled dataframes
            # pd.DataFrame.spatial.from_featureclass(layer)
            output_file = os.path.join(geojson_dir, f"{layer}.geojson")
            gdf.to_file(output_file, driver='GeoJSON')
            # pd.DataFrame.spatial
            # Define the output GeoParquet file path
            output_file = os.path.join(parquet_dir, f"{layer}.parquet")

            # Write the GeoDataFrame to a GeoParquet file
            gdf.to_parquet(output_file, index=False)
            if first_crs is None:
                first_crs=gdf.crs
            if gdf.crs != first_crs:
                gdf = gdf.to_crs(first_crs)
            print(f"Successfully saved {layer} as {output_file}")
            gdf['source_layer'] = layer

            # Append the GeoDataFrame to the list
            gdf_list.append(gdf)

        except Exception as e:
            print(f"Failed to process {layer}: {e}")


    combined_gdf = pd.concat(gdf_list, ignore_index=True)

    output_file = os.path.join(parquet_dir, f'Full_{collection_name}.parquet')

    # Save the combined GeoDataFrame as a single GeoParquet file
    combined_gdf.to_parquet(output_file, index=False)
    # arcpy.ClearEnvironment(arcpy.env.workspace)
    arcpy.env.workspace = None

    gdb_zip = create_gdb_zip(gb, output_gdb)
    json_zip = create_gdb_zip(gb, geojson_dir)
    # gpkg_zip= create_gdb_zip(gpkg_path)
    s3 = boto3.client('s3')

    # Specify file, bucket, and optional object name
    bucket_name = gb.configs.etl_s3_bucket  # S3 bucket name

    # s3.put_object(Bucket=bucket_name, Key=f"{schema}")


    # Connect to your file geodatabase

    upload_directory_to_s3(gb, local_output, collection_name)
    # arcpy.env.workspace = output_gdb
    # upload_to_s3(s3, f, bucket_name, s3_path)
    # for f in [gdb_zip, gpkg_path, json_zip]:
    #     try:
    #         logging.info(f"Uploading {f} to S3 Bucket: {bucket_name}")
    #         base_name = os.path.basename(f)
    #         s3_path = f"{collection_name}/{base_name}"
    #         if "geojson" in f:
    #             s3_path = f"{collection_name}/geojson/{base_name}"
    #         upload_to_s3(s3, f, bucket_name, s3_path)
    #     except Exception as fe:
    #         print(fe)
    #
    #     # upload_directory_to_s3(bucket_name, output_gdb, collection_name)
    #
    #
    # upload_directory_to_s3(bucket_name, geojson_dir, collection_name)
    # upload_directory_to_s3(bucket_name, parquet_dir, collection_name)

    # cleanup_file([gdb_zip,gpkg_path,json_zip,geojson_dir, parquet_dir])

# Function to upload a file to S3
def upload_to_s3(s3, file_name, bucket, object_name=None):
    # If S3 object_name was not specified, use the file_name
    if object_name is None:
        object_name = file_name

    try:
        # Upload the file to S3
        s3.upload_file(file_name, bucket, object_name)
        print(f"File {file_name} uploaded to {bucket}/{object_name}")
    except FileNotFoundError:
        print("The file was not found")
    except NoCredentialsError:
        print("Credentials not available")




    # # Path to the GDB containing layers and tables (exported in the previous step)
    # gdb_path = r"D:\data\ib\ib.gdb.zip"
    #
    # # Upload the zipped GDB
    # item_properties = {
    #     'title': 'Ice Jam',
    #     'tags': 'SDE, layers, tables, feature service',
    #     'description': 'Feature service with layers and tables from Ice Jam.'
    # }
    #
    # uploaded_item = gis.content.add(item_properties, gdb_path)
    #
    #
    #
    # # Publish the zipped GDB as a feature service
    # published_item = uploaded_item.publish()
    #
    # print(f"Feature service published at: {published_item.url}")

def load_product_source_details(gb):
    try:
        # Always want to recreate sde connection
        if not os.path.exists(gb.sde_connection):
            egis_utils.create_catalog_connection(gb, staged_env='dev', connection_name='connection-catalog')
        gb.logger.info("Retrieving data product details from RDBMS")
        sde_conn = arcpy.ArcSDESQLExecute(gb.sde_connection)
        where_clause = f"where data_product_id = {gb.product.product_id} and source_id = {gb.product.source_id}"
        # Build the SQL query with WHERE clause
        sql = f'''
                SELECT path, schema_prefix as collection_schema, name as collection_name, 
                    coalesce(properties_json->>'tags','') tags,
                	properties_json->>'copyrightText' copyright_text,
                    properties_json ->>'description' description,
                    properties_json ->>'serviceDescription' serviceDescription	
                FROM etl_loader.etl_control_view {where_clause}'''

        gb.logger.info(f"SQL to get data for service definition: {sql}")
        rows = sde_conn.execute(sql)

        df = pd.DataFrame(rows, columns=["path", "collection_schema", "collection_name","tags",
                                         "copyright_text","description","service_description"])
        first_row = df.iloc[0]

        gb.product.collection_name = first_row['collection_name']
        gb.product.schema = first_row['collection_schema'].lower()
        gb.load_schema =gb.product.schema
        gb.product.source_path = first_row['path']
        gb.description = first_row['description']
        gb.service_description = first_row['service_description']
        gb.copyright_text = first_row['copyright_text']
        gb.tags = first_row['tags']

        gb.logger.info(f"{gb.product.schema} : {gb.product.collection_name} : {gb.product.source_path}")

    except Exception as e:
        gb.logger.error("Error Retrieving data product details from RDBMS", e)

def process_args():
    parser = argparse.ArgumentParser(description='Process inputs to load data')
    parser.add_argument(
        "--data_product_id",
        type=int,
        help="Data Product Id",
    )
    parser.add_argument(
        "--source_id",
        type=int,
        help="Data Product Source Id",
    )
    parser.add_argument(
        "--config_file",
        type=str,
        help="config_file",
    )
    parser.add_argument(
        "--log_dir",
        type=str,
        help="log_dir",
    )
    parsed_args = parser.parse_args()
    # args = vars(parsed_args)
    return parsed_args


class Globals:
    def __init__(self, args, configs, logger):
        now = datetime.datetime.now()
        self.dts = now
        self.args = args
        self.configs = configs
        self.logger = logger
        self.sde_connection = f"{configs.sde_root}\connection-catalog.sde"
        self.product = egis_utils.DataProduct(args.data_product_id, args.source_id)

def init():

    now = datetime.datetime.now()
    formatted_date = now.strftime('%Y%m%d%H%M%S')
    args = process_args()
    log_dir = args.log_dir
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"{formatted_date}_load.log")
    logger = egis_utils.initialize_logger(log_file, debug=True)
    try:
        config_json = egis_utils.load_json_from_file(args.config_file, logger)
    except Exception as e:
        logger.error('Execution failed {e}', e)
        sys.exit(1)

    return Globals(args, SimpleNamespace(**config_json), logger)

def main():

    gb = init()
    load_product_source_details(gb)
    product_name = gb.product.collection_name
    publish_layers(gb)


if __name__ == "__main__":
    main()