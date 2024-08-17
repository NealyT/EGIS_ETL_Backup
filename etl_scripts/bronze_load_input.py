"""
bronze_load_input.py
Project: USACE: BAH: EGIS Authoritative Source Repository
Date: August 2024

"""

import argparse
import os
import time
import subprocess
import json
import sys
import arcpy
import logging
import datetime
import pandas as pd


class Globals:
    def __init__(self, dts, args, logger):

        formatted_dts =dts
        product_id = args["data_product_id"]
        source_id = args["source_id"]
        output_dir = args["output_dir"]
        sde_root = args["sde_root"]
        catalog_sde = args["catalog_sde"]
        db_name = args["db_name"]


        self.sde_connection = f"{sde_root}\{catalog_sde}-{db_name}.sde"
        # self.stage_connection =f"{sde_connection_base}/{data_product.schema}.sde"
        self.product_path = output_dir
        self.dts = formatted_dts
        self.product = DataProduct(product_id, source_id)
        self.logger = logger
        self.sde_root = sde_root
        self.db_name = db_name
        self.user_connection = None



class DataProduct:
    def __init__(self, product_id, source_id, collection_name = None, schema = None, source_path = None):
        self.product_id = product_id
        self.source_id = source_id
        self.collection_id = product_id
        self.collection_name = collection_name
        self.schema = schema
        self.source_path = source_path


def load_data(gb, sql, conn=None):
    try:
        if conn is None:
            conn = gb.sde_connection

        sde_conn = arcpy.ArcSDESQLExecute(conn)

        # rows = cursor.execute(sql).fetchall()
        rows = sde_conn.execute(sql)
        # Create a pandas DataFrame from the fetched data
        df = pd.DataFrame(rows)
        return df;
    except Exception as e:
        print(f"Error: {e}")

def load_product(gb) :

    try:

        sde_conn = arcpy.ArcSDESQLExecute(gb.sde_connection)
        where_clause = f"where collection_id = {gb.product.product_id} and source_id = {gb.product.source_id}"
        # where_clause = ""
        # Build the SQL query with WHERE clause
        sql = f"SELECT path, collection_schema, collection_name FROM meta.collection_hosted_urls {where_clause}"

        # rows = cursor.execute(sql).fetchall()
        rows = sde_conn.execute(sql)
        # Create a pandas DataFrame from the fetched data
        df = pd.DataFrame(rows, columns=["path", "collection_schema", "collection_name"])
        first_row = df.iloc[0]
        gb.product.collection_name = first_row['collection_name']
        gb.product.schema = first_row['collection_schema']
        gb.product.source_path =first_row['path']
        gb.logger.info(f"Processing Data Product: {gb.product.collection_name} : Path: {gb.product.source_path}")

    except Exception as e:
        print(f"Error: {e}")

def init_globals() -> Globals:
    logger = initialize_logger()
    logger.info("Started Load Process, Initializing")
    now = datetime.datetime.now()
    args = process_args()
    gb = Globals(now, args, logger)
    logger.info(f"Loading Product data for {gb.product.product_id} Source {gb.product.source_id}")
    load_product( gb)
    gb.user_connection = f"{gb.sde_root}\{gb.product.schema.lower()}-{gb.db_name}.sde"
    return gb

def initialize_logger():
    logger = logging.getLogger(__name__)

    stream_handler = logging.StreamHandler()
    logger.setLevel(logging.DEBUG)
    logger.addHandler(stream_handler)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    stream_handler.setFormatter(formatter)

    return logger

def process_args():
    parser = argparse.ArgumentParser(description='Process some integers.')
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
        "--sde_root",
        type=str,
        help="path to the directory where sde connection files are stored.",
    )
    parser.add_argument(
        "--catalog_sde",
        type=str,
        help="catalog user sde connection prefix.",
    )
    parser.add_argument(
        "--db_name",
        type=str,
        help="sde db name",
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        help="path to the directory where all the data will be published.",
    )
    parsed_args = parser.parse_args()
    args = vars(parsed_args)
    return args

def create_schema(gb):
    gb.logger.info(f"Checking if {gb.product.schema} Schema exists")

def create_user_connection(gb):
    gb.logger.info(f"Checking if {gb.user_connection} connection file exists")

def main():

    gb = init_globals()
    create_schema(gb)
    gb.logger.info("Completed Load Process")
if __name__ == "__main__":
    main()
