import argparse
import os
import arcpy
import logging
import subprocess
import datetime
import shutil
import boto3
import pandas as pd
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

def create_gdb_zip(o):
    zipFile = f"{o}.7z"
    cleanup_file([zipFile])
    try:
        print(f"creating {zipFile}")
        subprocess.run(['7z', 'a', zipFile, o])
        # Use subprocess.run with check=True to raise an exception on non-zero exit codes
        result = subprocess.run(
            ['7z', 'a', zipFile, o],
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

def upload_directory_to_s3(bucket_name, directory_path, s3_prefix=''):
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
def publish_layers():
# Connect to the SDE database
    sde_connection = f"{gb.sde_root}\server_connection.sde"
    arcpy.env.workspace = sde_connection
    schema = gb.schema


    collection_name = 'Ice_Jam_Database'
    feature_classes = arcpy.ListFeatureClasses()
    schema_classes = [fc for fc in feature_classes if f'.{schema}.' in fc]

    tables =  arcpy.ListTables()
    schema_tables = [fc for fc in tables if f'.{schema}.' in fc]

    output_gdb = os.path.join(rf"{gb.sde_root}",f"{schema}.gdb")
    gpkg_path = os.path.join(rf"{gb.sde_root}",f"{schema}.gpkg")
    cleanup_file([output_gdb, gpkg_path])

    # Create a GeoPackage
    arcpy.CreateFileGDB_management(rf"{gb.sde_root}",f"{schema}.gdb")
    arcpy.management.CreateSQLiteDatabase(gpkg_path, "GEOPACKAGE")
    arcpy.FeatureClassToGeodatabase_conversion(schema_classes + schema_tables, output_gdb)
    arcpy.FeatureClassToGeodatabase_conversion(schema_classes + schema_tables, gpkg_path)
    # # Export feature classes and tables to the GDB
    geojson_dir = os.path.join(gb.sde_root, "geojson")
    os.makedirs(geojson_dir, exist_ok=True)
    parquet_dir = os.path.join(f'{gb.sde_root}', 'geoparquet')
    os.makedirs(parquet_dir, exist_ok=True)
    layers = fiona.listlayers(output_gdb)
    gdf_list = []
    # Iterate over each layer and convert it to GeoParquet
    first_crs = None
    for layer in layers:
        try:
            # Read the layer into a GeoDataFrame
            gdf = gpd.read_file(output_gdb, layer=layer)
            output_file = os.path.join(geojson_dir, f"{layer}.geojson")
            gdf.to_file(output_file, driver='GeoJSON')
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

    gdb_zip = create_gdb_zip(output_gdb)
    json_zip = create_gdb_zip(geojson_dir)
    # gpkg_zip= create_gdb_zip(gpkg_path)
    s3 = boto3.client('s3')

    # Specify file, bucket, and optional object name
    bucket_name = gb.output_bucket  # S3 bucket name

    # s3.put_object(Bucket=bucket_name, Key=f"{schema}")


    # Connect to your file geodatabase
    arcpy.env.workspace =output_gdb


    for f in [gdb_zip, gpkg_path, json_zip]:
        try:
            logging.info(f"Uploading {f} to S3 Bucket: {bucket_name}")
            base_name = os.path.basename(f)
            s3_path = f"{collection_name}/{base_name}"
            if "geojson" in f:
                s3_path = f"{collection_name}/geojson/{base_name}"
            upload_to_s3(s3, f, bucket_name, s3_path)
        except Exception as fe:
            print(fe)

        # upload_directory_to_s3(bucket_name, output_gdb, collection_name)


    upload_directory_to_s3(bucket_name, geojson_dir, collection_name)
    upload_directory_to_s3(bucket_name, parquet_dir, collection_name)

    cleanup_file([gdb_zip,gpkg_path,json_zip,geojson_dir, parquet_dir])

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



def process_args():
    parser = argparse.ArgumentParser(description='Process inputs to load data')

    parser.add_argument(
        "--output_bucket",
        type=str,
        help="path to the directory where sde connection files are stored.",
    )
    parser.add_argument(
        "--sde_root",
        type=str,
        help="path to the directory where sde connection files are stored.",
    )
    parser.add_argument(
        "--schema",
        type=str,
        help="ib",
    )
    parsed_args = parser.parse_args()
    args = vars(parsed_args)
    return args


class Globals:
    def __init__(self, dts, args):
        formatted_dts = dts
        self.sde_root = args["sde_root"]
        self.output_bucket = args["output_bucket"]
        self.schema = args["schema"]
        self.dts = formatted_dts


def init_globals() -> Globals:
    logger.info("Started Publishing Process, Initializing")
    now = datetime.datetime.now()
    args = process_args()
    gb = Globals(now, args)
    # logger.info(f"Loading Product data for {gb.product.product_id} Source {gb.product.source_id}")
    return gb

def initialize_logger():
    logger = logging.getLogger(__name__)

    stream_handler = logging.StreamHandler()
    logger.setLevel(logging.DEBUG)
    logger.addHandler(stream_handler)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    stream_handler.setFormatter(formatter)
    # Add the filter to the DBHandler

    return logger

def main():
    global logger
    global gb
    global etl_run_id
    global load_id

    logger = initialize_logger()
    gb = init_globals()
    publish_layers()
    # load_product_source_details()
    # gb.etl_record = ETLRecord(gb.product.source_id, "INIT", "RUNNING")
    # gb.etl_record.etl_run_id = insert_record(gb.etl_record)
    # fc = initialize_load_history()
    #
    # create_load_schema()
    # create_user_connection()
    # gb.etl_record.step = 'LOADING'
    # update_record(gb.etl_record, ["load_id", "step"])
    # load_sde(fc)
    # logger.info("Completed Load Process")
    # gb.etl_record.step = 'COMPLETED'
    # gb.etl_record.end_datetime = datetime.datetime.now()
    # update_record(gb.etl_record, ["load_id", "step","end_datetime"])

if __name__ == "__main__":
    main()