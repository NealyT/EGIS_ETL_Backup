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
import datetime


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
        # where_clause = "where acronym = 'NSMF'"
        where_clause = ""
        # Build the SQL query with WHERE clause
        sql = f"SELECT url, acronym, collection_id, collection_name FROM catalog.collection_hosted_url {where_clause}"

        # Execute the query
        cur.execute(sql)

        # Fetch all the rows at once (adjust fetchall size based on data volume)
        rows = cur.fetchall()

        # Close the cursor and connection objects
        cur.close()
        conn.close()

        # Create a pandas DataFrame from the fetched data
        df = pd.DataFrame(rows, columns=["url", "acronym", "collection_id", "collection_name"])

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


def main():
    #feature_layer_url = "https://services7.arcgis.com/n1YM8pTrFmm7L4hs/ArcGIS/rest/services/CSPI_DataCall_AllData/FeatureServer"
    ogr_location = r"C:\Program Files\QGIS 3.38.0\bin\ogr2ogr.exe"
    base_location = arcpy.GetParameterAsText(0)
    sde_connection = arcpy.GetParameterAsText(1)
    desc = arcpy.Describe(sde_connection)
    dbname = desc.connectionProperties.database
    host = desc.connectionProperties.instance.split(":")[2]
    now = datetime.datetime.now()
    # Convert to string in a specific format (YYYY-MM-DD HH:MM:SS)
    formatted_dts = now.strftime("%Y-%m-%d %H:%M:%S")

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

    collection_data_rows = []
    headers = ['Collection_Code',
               'Collection_Id',
               'Collection_Name',
               'load_datetimestamp',
               'wkid',
               'layer_count',
               'table_count',
               'load_status',
               'source_file_path',
               'url',
               'serviceItemId',
               'serviceDescription',
               'description']
    table_data = {}
    # Create geojson files for each service, layer
    for index, row in df.iterrows():
        acronym = row['acronym']
        collection_name = row['collection_name']
        collection_id = row['collection_id']
        url = row['url'].strip()
        print(url)
        try:
            response = requests.get(url, params={"f": "json"})
            urlJson = response.json()
            print(urlJson)

            layer_count = len(urlJson["layers"]) if "layers" in urlJson else 0
            table_count = len(urlJson["tables"]) if "tables" in urlJson else 0

            symlink = f"d:\\bah\\{acronym}"
            json_file_name = collection_name.strip().replace(" ", "_")
            collection_file_path = f"{symlink}\\{json_file_name}.json"

            serviceItemId = urlJson['serviceItemId'] if 'serviceItemId' in urlJson else ''
            serviceDescription = urlJson['serviceDescription'] if 'serviceDescription' in urlJson else ''
            description = urlJson['description'] if 'description' in urlJson else ''
            srid = ''
            if 'spatialReference' in urlJson:
                if 'wkid' in urlJson['spatialReference']:
                    srid = urlJson['spatialReference']['wkid']
            new_row = {'Collection_Code': acronym,
                       'Collection_Id': collection_id,
                       'Collection_Name': collection_name,
                       'load_datetimestamp': formatted_dts,
                       'wkid': srid,
                       'layer_count': layer_count,
                       'table_count': table_count,
                       'load_status': 'preloaded',
                       'source_file_path': collection_file_path,
                       'serviceItemId': serviceItemId,
                       'url': url,
                       'serviceDescription': f'{serviceDescription}',
                       'description': f'{description}'}

            # new_row = { acronym, collection_id,collection_name,urlJson['serviceItemId'],urlJson['serviceDescription'],
            #            url,urlJson['description'],urlJson['spatialReference']['wkid'],layer_count,table_count,
            #            collection_file_path, formatted_dts}
            print(new_row)
            collection_data_rows.append(new_row)
            output_location = os.path.join(base_location, acronym)

            if "tables" in urlJson:
                for child in urlJson["tables"]:
                    name = child["name"]
                    standard_name = name.strip().replace(' ', '_').lower()
                    gfile = os.path.join(output_location, f"{standard_name}.csv")
                    if os.path.exists(gfile):
                        table_name = f'{acronym}.{standard_name}'
                        # print(table_name)
                        # postGIS(ogr_location, acronym, gfile, table_name, host, dbname, user_name, password)
            if "layers2" in urlJson:
                for child in urlJson["layers"]:
                    name = child["name"]
                    type = child['geometryType'].lower()
                    url_id = child["id"]
                    child_url = f"{url}/{url_id}"

                    standard_name = name.strip().replace(' ', '_').lower()

                    output_fc = f"{sde_connection}/{standard_name}"
                    #print(f"{name},{standard_name},{type},{child_url},{output_fc}")

                    if not arcpy.Exists(output_fc):
                        try:
                            if arcpy.Exists(output_fc):
                                arcpy.management.Delete(output_fc)

                            arcpy.conversion.ExportFeatures(child_url, output_fc)
                            desc = arcpy.da.Describe(output_fc)
                            arcpy.AddGlobalIDs_management(output_fc)
                            print(desc)

                        except Exception as e:
                            print(e)

                            # arcpy.conversion.FeatureClassToGeodatabase(
                            #     Input_Features=r"'Coastal Systems Portfolio Initiative\cspi_csrm_aer_overview';'Coastal Systems Portfolio Initiative\cspi_damagerisk'",
                            #     Output_Geodatabase=r"D:\Users\nealie.t\Documents\ArcGIS\Projects\EGIS_1\cpsi_collection.gdb"
                            # )
    collection_data = pd.DataFrame(collection_data_rows, columns=headers)
    # Export to CSV
    file_name = r'd:\\data\\temp.csv'
    collection_data.to_csv(file_name, index=False)

    # Import to SDE
    out_table = f"{sde_connection}/load_collection"
    print('-----------------------------------------')
    print(out_table)
    print(collection_data.head(2))
    postGIS(ogr_location, acronym, file_name, "load_collection", host, dbname, user_name, password)


if __name__ == "__main__":
    main()
