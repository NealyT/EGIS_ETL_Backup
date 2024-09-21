import shutil
import subprocess
import arcpy
import os
import csv
import json

import psycopg2
import requests
import tkinter as tk
from tkinter import simpledialog
import pandas as pd


def read_geojson(file_path):
    with open(file_path, 'r') as f:
        data = json.load(f)
    return data
def check_schema(schema_name, host, dbname, user, password):
    conn = None
    cur = None

    query = """
      SELECT EXISTS (
          SELECT 1
          FROM pg_catalog.pg_namespace
          WHERE nspname = %s
      );
  """

    try:
        lschema = schema_name.lower()
        conn = psycopg2.connect(dbname=dbname, user=user, password=password, host=host)
        cur = conn.cursor()

        cur.execute(query, (lschema,))
        schema_exists = cur.fetchone()[0]

        if schema_exists:
            print(f"The schema '{lschema}' exists.")
        else:
            print(f"The schema '{lschema}' does not exist.")
            create_schema_query = f"CREATE SCHEMA {lschema} AUTHORIZATION {user};"

            cur.execute(create_schema_query)
            conn.commit()
    except Exception as e:
        print(f"Error: {e}")
        return pd.DataFrame()  # Return empty DataFrame in case of errors
    finally:
        if cur is not None:
            cur.close()
        if conn is not None:
            conn.close()


def load_urls_from_db(host, dbname, user, password):
    # Connect to the PostgreSQL database
    conn = None
    cur = None
    try:
        conn = psycopg2.connect(dbname=dbname, user=user, password=password, host=host)

        # Create a cursor object
        cur = conn.cursor()
        # where_clause = " WHERE collection_id = 3"
        where_clause = "where acronym = 'NDC'"
        # where_clause = ""
        # Build the SQL query with WHERE clause
        sql = f"SELECT url, acronym FROM catalog.collection_hosted_url {where_clause}"

        # Execute the query
        cur.execute(sql)

        # Fetch all the rows at once (adjust fetchall size based on data volume)
        rows = cur.fetchall()

        # Close the cursor and connection objects
        cur.close()
        conn.close()

        # Create a pandas DataFrame from the fetched data
        df = pd.DataFrame(rows, columns=["url", "acronym"])

        return df

    except Exception as e:
        print(f"Error: {e}")
        return pd.DataFrame()  # Return empty DataFrame in case of errors
    finally:
        if cur is not None:
            cur.close()
        if conn is not None:
            conn.close()


def load_urls_from_file(location):
    conn = None
    try:
        # Connect to the PostgreSQL database
        path = os.path.join(location, 'collection_hosted_url.csv')
        df = pd.read_csv(path, delimiter=',')
        return df
    except Exception as e:
        print(e)


def load_data(ogr_location, base_url, product, output_location, urlJson, host, dbname, user_name, password,
              table_data={}, post_data=False):
    file_path = os.path.abspath(output_location)
    print("Product path = " + file_path)
    if os.path.exists(file_path):
        shutil.rmtree(output_location)
    os.makedirs(file_path)
    if "layers" in urlJson:
        for child in urlJson["layers"]:
            child_layer = arcpy.FeatureSet()
            entity_type = child.get('geometryType')
            if entity_type is None:
                entity_type = 'Table'
            else:
                entity_type = entity_type.replace('esriGeometry', '')

            print(f"Loading Layer: {child['name']}...")

            url = f'{base_url}/{child["id"]}?f=pjson'
            standard_name = child["name"].strip().replace(' ', '_').lower()

            response = requests.get(url)
            esrijson_data = json.loads(response.text)

            child_layer.load(url)
            try:
                jsonChild = json.loads(child_layer.JSON)
            except Exception as e:
                jsonChild=esrijson_data

            try:
                if hasattr(child_layer, "GeoJSON"):
                    child_data = json.loads(child_layer.GeoJSON)
                    first_child_properties = child_data["features"][0]["properties"]
                    field_names = list(first_child_properties.keys())
                else:

                    child_data = {
                        "type": "FeatureCollection",
                        "features": jsonChild["features"]  # Assuming 'featureset' is a list of GeoJSON features
                    }
                    field_names = [field["name"] for field in jsonChild["fields"]]
                    saveJson(standard_name, child_layer, output_location)

                # Get the feature count from the 'features' key
                feature_count = len(child_data["features"])
                # Get the feature count
                feature_count2 = int(arcpy.GetCount_management(url)[0])
                print(f"{child['name']} had {feature_count} records returned, desc says {feature_count2}")
                print(field_names)
                table_data[child["name"]] = field_names
                standard_name = child["name"].strip().replace(' ', '_').lower()
                if hasattr(child_layer, "GeoJSON"):
                    file_name = saveGeoJson(standard_name, child_layer, output_location)
                else:
                    file_name = convertEsriJsonToGeoJson(ogr_location,output_location, standard_name)

            except Exception as e:
                print(e)
    if "tables" in urlJson:
        for child in urlJson["tables"]:
            url = f'{base_url}/{child["id"]}'
            desc = arcpy.da.Describe(url)
            print(f"Loading Table: {child['name']}...")
            standard_name = child["name"].strip().replace(' ', '_').lower()
            child_layer = arcpy.RecordSet(desc["catalogPath"])
            field_names = [field.name for field in desc["fields"]]
            table_data[child["name"]] = field_names
            file_name = dumpCSV(standard_name, child_layer, output_location)

    if "tables" not in urlJson and "layers" not in urlJson:
        feature_layer = arcpy.FeatureSet()
        feature_layer.load(base_url)

    return table_data


def get_credentials():
    root = tk.Tk()
    root.withdraw()  # Hide the root window

    username = simpledialog.askstring("Credentials", "Enter your username:")
    password = simpledialog.askstring("Credentials", "Enter your password:", show='*')

    return username, password


def get_token(portal_url, username=None, password=None):
    if not username or not password:
        username, password = get_credentials()

    url = f"{portal_url}/sharing/rest/generateToken"
    params = {
        'f': 'json',
        'username': username,
        'password': password,
        'referer': portal_url,
        'expiration': 60  # Token expiration time in minutes
    }
    response = requests.post(url, data=params)
    if response.status_code == 200:
        token = response.json().get('token')
        return token
    else:
        raise Exception("Unable to get token")


def saveGeoJson(name, featureLayer, output_location):
    # Define the output location and file name
    file_path = None

    try:
        output_file_name = f"{name}.geojson"

        print(f'Saving file {output_location}/{name}.geojson...')
        file_path = os.path.join(output_location, output_file_name)

        with open(file_path, 'w', encoding='utf-8') as file:
            if hasattr(featureLayer, 'GeoJSON'):
                file.write(featureLayer.GeoJSON)

        print(f"Data exported successfully to {output_location}\\{output_file_name}")
    except Exception as e:
        print(e)
        print(f"Problem generating geojson file {file_path}")
    return file_path


def saveJson(name, featureLayer, output_location):
    # Define the output location and file name
    file_path = None

    try:
        output_file_name = f"{name}.json"

        print(f'Saving file {output_location}/{name}.json...')
        file_path = os.path.join(output_location, output_file_name)

        with open(file_path, 'w', encoding='utf-8') as file:
            if hasattr(featureLayer, 'JSON'):
                file.write(featureLayer.JSON)

        print(f"Data exported successfully to {output_location}\\{output_file_name}")
    except Exception as e:
        print(e)
        print(f"Problem generating geojson file {file_path}")
    return file_path


def dumpTableData(product, output_location, name, table_data):
    output_file_name = f"{name}.csv"
    file_path = os.path.join(output_location, output_file_name)
    with open(file_path, 'a', newline='') as csvfile:
        csv_writer = csv.writer(csvfile)
        # Get field names from the recordset
        for table, fields in table_data.items():
            csv_columns = [product, table, *fields]
            csv_writer.writerow(csv_columns)
    print(f"Successfully dumped recordset data to {file_path}")


def dumpCSV(name, record_set, output_location):
    desc = arcpy.Describe(record_set)

    record_data = json.loads(record_set.JSON)
    output_file_name = f"{name}.csv"
    file_path = os.path.join(output_location, output_file_name)
    with open(file_path, 'w', newline='') as csvfile:
        # Create CSV writer object
        csv_writer = csv.writer(csvfile)
        desc = arcpy.Describe(record_set)
        # Get field names from the recordset
        field_names = [field.name for field in desc.fields]
        # Write header row
        csv_writer.writerow(field_names)

        # Iterate through records and write to CSV
        for feature in record_data["features"]:
            # Extract data as a list
            data_row = feature["attributes"]
            data_values = []
            for attribute in field_names:
                data_value = data_row.get(attribute)
                data_values.append(data_value)

            csv_writer.writerow(data_values)

    print(f"Successfully dumped recordset data to {file_path}")
    return file_path


def convertEsriJsonToGeoJson(ogr_location, output_location, name):
    file_path = os.path.join(output_location, f"{name}.geojson")
    file_path2 = os.path.join(output_location, f"{name}.json")

    command = [
        ogr_location,
        "-f", "GeoJSON",  # Output format
        file_path,  # Input GeoJSON file
        file_path2  # Name of the output layer (table)
    ]
    print(command)
    #
    # # Run ogr2ogr as a subprocess
    try:
        subprocess.check_call(command)
        print("File conversion successful!")
        return file_path
    except Exception as error:
        print(f"Error during ogr2ogr execution: {error}")


def postGIS(ogr_location, product, file_path, table_name, host, dbname, user, password):
    check_schema(product, host, dbname, user, password)
    postgres_connection_string = f'PG:host={host} dbname={dbname} user={user} password={password}'
    flags = '-skipfailures'

    command = [
        ogr_location,
        "-f", "PostgreSQL",  # Output format
        postgres_connection_string,  # PostgreSQL connection string
        file_path,  # Input GeoJSON file
        "-nln", table_name,  # Name of the output layer (table)
        "-overwrite",  # Overwrite the table if it already exists
        "-skipfailures",

    ]
    #
    # # Run ogr2ogr as a subprocess
    try:
        subprocess.check_call(command)
        print("Data conversion successful!")

    except Exception as error:
        print(f"Error during ogr2ogr execution: {error}")



if __name__ == "__main__":
    #feature_layer_url = "https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/CSPI_DataCall_AllData/FeatureServer"
    ogr_location = r"C:\Program Files\QGIS 3.38.0\bin\ogr2ogr.exe"
    base_location = arcpy.GetParameterAsText(0)
    sde_connection = arcpy.GetParameterAsText(1)
    desc = arcpy.Describe(sde_connection)
    dbname = desc.connectionProperties.database
    host = desc.connectionProperties.instance.split(":")[2]

    # dbname = arcpy.GetParameterAsText(3)
    user_name = arcpy.GetParameterAsText(4)
    password = arcpy.GetParameterAsText(5)
    if not user_name or not password:
        user_name, password = get_credentials()
    arcpy.env.workspace = sde_connection
    dadesc = arcpy.da.Describe(sde_connection)

    # print(desc.workspaceType)  # Output: 'SDE'
    # print(desc.connectionProperties)
    for key, value in dadesc.items():
        print(f"{key}: {value}")
    df = load_urls_from_db(host, dbname, user_name, password)

    table_data = {}
    # Create geojson files for each service, layer
    for index, row in df.iterrows():
        acronym = row['acronym']
        url = row['url'].strip()
        print(url)
        response = requests.get(url, params={"f": "json"})

        urlJson = response.json()
        output_location = os.path.join(base_location, acronym)
        layers =[]
        if "tables2" in urlJson:
            for child in urlJson["tables"]:
                name = child["name"]
                standard_name = name.strip().replace(' ', '_').lower()
                gfile = os.path.join(output_location, f"{standard_name}.csv")
                if os.path.exists(gfile):

                    table_name = f'{acronym}.{standard_name}'
                    print(table_name)
                    postGIS(ogr_location, acronym, gfile, table_name, host, dbname, user_name, password)
        if "layers" in urlJson:
            for child in urlJson["layers"]:
                name =child["name"]
                type = child['geometryType'].lower()
                url_id = child["id"]
                child_url = f"{url}/{url_id}"
                print(child_url)
                standard_name = name.strip().replace(' ', '_').lower()
                gfile = os.path.join(output_location,f"{standard_name}.geojson")
                gtype = 'POINT'
                if 'line' in type:
                    gtype = 'POLYLINE'
                elif 'polygon' in type:
                    gtype = 'POLYGON'

                output_fc = f"{sde_connection}/{standard_name}"
                spatial_reference = None
                if not arcpy.Exists(output_fc):
                    if os.path.exists(gfile):
                        try:

                            if gtype != 'POLYGON2':
                                temp_fc = "in_memory/temp_fc"
                                if arcpy.Exists(temp_fc):
                                    arcpy.management.Delete(temp_fc)

                                arcpy.JSONToFeatures_conversion(gfile, temp_fc, gtype)
                                # arcpy.AlterField_management(temp_fc, "OBJECTID", "DELETE_OBJECTID")
                                # arcpy.AlterField_management(temp_fc, "OBJECTID_1", "OBJECTID")
                                arcpy.AlterField_management(temp_fc, "OBJECTID_1", "ORIG_OBJECTID")
                                feature_count2 = arcpy.GetCount_management(temp_fc)
                                desc = arcpy.da.Describe(temp_fc)
                                print(f"Loading Layer: {standard_name} {feature_count2} records ({type} {gtype})...")
                                names = [field.name for field in desc["fields"]]
                                print(names)
                                # Check if the output feature class exists and delete it if it does
                                if arcpy.Exists(output_fc):
                                    arcpy.management.Delete(output_fc)

                                # FeatureC
                                # arcpy.FeatureClassToFeatureClass_conversion(temp_fc, sde_connection, standard_name)
                                arcpy.conversion.ExportFeatures(child_url, output_fc)
                                layers.append(output_fc)
                                desc = arcpy.da.Describe(output_fc)
                                spatial_reference=desc["spatialReference"]
                                # arcpy.conversion.ExportFeatures(gfile, output_fc)
                        except Exception as e:
                            print(e)
    # collection_name ="National_Channels_Framework"
    # featureDataSet = arcpy.management.CreateFeatureDataset(
    #     out_dataset_path=sde_connection,
    #     out_name=f"{collection_name}_Database",
    #     spatial_reference=spatial_reference
    # )
    #
    # arcpy.conversion.FeatureClassToGeodatabase(
    #     Input_Features=layers,
    #     Output_Geodatabase=featureDataSet
    # )