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
    def __init__(self, logger):
        now = datetime.datetime.now()
        args = process_args()
        # Convert to string in a specific format (YYYY-MM-DD HH:MM:SS)
        formatted_dts = now.strftime("%Y-%m-%d %H:%M:%S")
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
        logger.info(f"Loading Product data for {product_id} Source {source_id}")
        self.product = load_product(self.sde_connection, product_id, source_id, logger)


class DataProduct:
    def __init__(self, product_id, source_id, collection_id, collection_name, schema, source_path):
        self.product_id = product_id
        self.source_id = source_id
        self.collection_id = collection_id
        self.collection_name = collection_name
        self.schema = schema
        self.source_path = source_path

def load_product(connection, product_id, source_id, logger) -> None|DataProduct:

    try:

        sde_conn = arcpy.ArcSDESQLExecute(connection)
        where_clause = f"where collection_id = {product_id} and source_id = {source_id}"
        # where_clause = ""
        # Build the SQL query with WHERE clause
        sql = f"SELECT path, collection_schema, collection_name FROM meta.collection_hosted_urls {where_clause}"

        # rows = cursor.execute(sql).fetchall()
        rows = sde_conn.execute(sql)
        # Create a pandas DataFrame from the fetched data
        df = pd.DataFrame(rows, columns=["path", "collection_schema", "collection_name"])
        first_row = df.iloc[0]

        dp = DataProduct(product_id, source_id, product_id,  first_row['collection_name'], first_row['collection_schema'], first_row['path'])
        logger.info(f"Processing Data Product: {dp.collection_name} : Path: {dp.source_path}")
        return dp
    except Exception as e:
        print(f"Error: {e}")



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

def main():
    logger = initialize_logger()
    logger.info("Started Load Process")
    globals = Globals(logger)
    logger.info("Completed Load Process")
if __name__ == "__main__":
    main()
