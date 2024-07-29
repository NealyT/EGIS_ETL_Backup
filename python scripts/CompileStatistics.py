'''
Explore options like pg_bulkload or pgloader for PostgreSQL

https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services
'''
import re
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


def contains_any(text, values):
    """Checks if the text contains any of the values in the list."""
    return any(value in text for value in values)


def get_credentials():
    root = tk.Tk()
    root.withdraw()  # Hide the root window

    username = simpledialog.askstring("Credentials", "Enter your username:")
    password = simpledialog.askstring("Credentials", "Enter your password:", show='*')

    return username, password


def load_urls_from_db(host, dbname, user, password):
    # Connect to the PostgreSQL database
    conn = None
    cur = None
    try:
        conn = psycopg2.connect(dbname=dbname, user=user, password=password, host=host)

        # Create a cursor object
        cur = conn.cursor()

        # Build the SQL query with WHERE clause
        sql = f"SELECT collection_id,collection_name,sample_url as factsheet2,urls,acronym,factsheet FROM catalog.product_configs"

        # Execute the query
        cur.execute(sql)

        # Fetch all the rows at once (adjust fetchall size based on data volume)
        rows = cur.fetchall()

        # Close the cursor and connection objects
        cur.close()
        conn.close()

        # Create a pandas DataFrame from the fetched data
        df = pd.DataFrame(rows, columns=["collection_id", "collection_name","factsheet2", "urls", "acronym", "factsheet"])

        return df

    except Exception as e:
        print(f"Error: {e}")
        return pd.DataFrame()  # Return empty DataFrame in case of errors
    finally:
        if cur is not None:
            cur.close()
        if conn is not None:
            conn.close()



def process_entity(base_url, child, rows=[]):
    try:
        url = f'{base_url}/{child["id"]}'

        feature_count2 = int(arcpy.GetCount_management(url)[0])
        entity_type = child.get('geometryType')
        if entity_type is None:
            entity_type = 'Table'
        else:
            entity_type = entity_type.replace('esriGeometry','')
        print(f"Loading Layer: {child['name']} {feature_count2} {entity_type} {url}")
        title = child['name'].replace(" ", "_")

        ltitle = title.lower()
        filters = []
        if contains_any(ltitle, ["dam", "structure"]) and 'damage' not in ltitle:
            filters.append("Structures")
        if contains_any(ltitle, ["dam", "levee", "reservoir"]) and 'damage' not in ltitle:
            filters.append("Dams")
        if contains_any(ltitle,
                        ["channel", "sea", "shore", "coast", "river", "canal", "harbour", "lake", "reservoir", "water",
                         "basin"]):
            filters.append("WaterBodies")
        if contains_any(ltitle, ["pipe"]):
            filters.append("PipeLines")
        if contains_any(ltitle, ["port", "linkton"]):
            filters.append("Commerce")
        if contains_any(ltitle, ["flood", "inundation", "levee"]):
            filters.append("Flood")
        if contains_any(ltitle, ["dock"]):
            filters.append("Docks")
        if contains_any(ltitle, ["dredg", "sediment"]):
            filters.append("Dredging")
        if contains_any(ltitle, ["coast", "cspi", "shore"]):
            filters.append("Coastal")
        if contains_any(ltitle, ["parcel", "port", "facility", "property"]):
            filters.append("Real Estate")


        new_row = {'Acronym': acronym, 'Collection_Name': collection_name, 'Entity_Name': child['name'],
                   'Entity_Name_Revised': ltitle, 'Record_Count': feature_count2,
                   'Entity_TYpe': entity_type,
                   'url': url, 'filters': ','.join(filters)}
        # df = df.append(new_row, ignore_index=True)
        rows.append(new_row)
    except Exception as e:
        print(f"{e}")

if __name__ == "__main__":


    df = pd.DataFrame(columns=['Acronym', 'Collection_Name', 'Entity_Name','Record_Count','url','filters'])
    output_location = arcpy.GetParameterAsText(0)
    host = arcpy.GetParameterAsText(1)
    dbname = arcpy.GetParameterAsText(2)
    user_name = arcpy.GetParameterAsText(3)
    password = arcpy.GetParameterAsText(4)
    if not user_name or not password:
        user_name, password = get_credentials()

    product_configs = load_urls_from_db(host, dbname, user_name, password)

    parentFilters = []
    rows = []
    for index, row in product_configs.iterrows():
        acronym = row['acronym']
        collection_name = row['collection_name']
        urls = []
        if 'urls' in row and not isinstance(row['urls'], float):
            urls = row['urls'].strip().split(";")

        for base_url in urls:

            if base_url != '':

                try:
                    print(f"Requesting data from url for {acronym}")
                    response = requests.get(base_url, params={"f": "json"})
                    urlJson = response.json()

                    if "layers" in urlJson:
                        for child in urlJson["layers"]:
                            process_entity(base_url, child, rows)

                    if "tables" in urlJson:
                        for child in urlJson["tables"]:
                            process_entity(base_url, child, rows)

                except Exception as e:
                    print(f"{e}")

    stats_file = os.path.join(output_location, 'targeted_22.csv')
    df = pd.DataFrame(rows)
    df.to_csv(stats_file)
