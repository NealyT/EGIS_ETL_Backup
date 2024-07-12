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
from arcgis.features import FeatureLayer
import pandas as pd


def load_model_from_file(path):
    conn = None
    try:  # Connect to the PostgreSQL database

        df = pd.read_csv(path, delimiter=',')
        return df;
    except Exception as e:
        print(e)

'''
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
RESEARCH UUID MORE
'''
if __name__ == "__main__":
    input_file = arcpy.GetParameterAsText(0)

    path = os.path.abspath(input_file)
    dir, tail = os.path.split(input_file)
    table_name = os.path.splitext(os.path.basename(input_file))[0].upper()
    file_name = os.path.join(dir,f"{table_name}.SQL")
    print(table_name)
    df = load_model_from_file(path)
    schema = 'sdsfie'

    with open(file_name, "w") as file:
        # Write data to the file
        file.write(f'''
        CREATE TABLE IF NOT EXISTS {schema}.{table_name}
        (''')

        for index, row in df.iterrows():
            model_name = row['Model Name']
            alias = row['Alias Name']
            definition = row['Definition']
            data_type = row['Data Type'].replace('(MAX)', '').lower()
            # print(data_type)
            col_type = "character varying"
            applicable = row['Applicable Geometry']

            if 'char' not in data_type:
                if data_type == 'yesorno':
                    col_type = 'boolean'
                elif data_type == 'guid':
                    col_type = 'uuid'
                elif data_type == 'datetime':
                    col_type = 'timestamp'
                else:
                    col_type = data_type
            key = ''
            if model_name == 'sdsId':
                key = f" PRIMARY KEY DEFAULT uuid_generate_v4() "
            comma = ','
            if index == (len(df) - 1):
                comma = ''
            file.write(f'{model_name} {col_type} {key}{comma}\n')

            # ogc_fid integer NOT NULL DEFAULT nextval('nid.national_inventory_dams_ogc_fid_seq'::regclass),
            # "dam name" character varying COLLATE pg_catalog."default",
            # "primary owner type" character varying COLLATE pg_catalog."default",
            # CONSTRAINT national_inventory_dams_pkey PRIMARY KEY (ogc_fid)
        file.write(f") TABLESPACE pg_default;\n")
        file.write(f''' 
               
        ALTER TABLE IF EXISTS {schema}.{table_name}
            OWNER to catalog;  ''')

