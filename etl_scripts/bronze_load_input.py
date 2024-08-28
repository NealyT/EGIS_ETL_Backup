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
    def __init__(self, dts, args):

        formatted_dts =dts
        product_id = args["data_product_id"]
        source_id = args["source_id"]
        output_dir = args["output_dir"]
        sde_root = args["sde_root"]
        staging_sde = args["staging_sde"]
        db_database = args["db_database"]
        db_env = args["db_env"]
        db_instance = args["db_instance"]


        self.sde_connection = f"{sde_root}\{staging_sde}-{db_database}.sde"
        self.product_path = output_dir
        self.dts = formatted_dts
        self.product = DataProduct(product_id, source_id)
        self.sde_root = sde_root
        self.staging_sde = staging_sde
        self.db_database = db_database
        self.db_env = db_env
        self.db_instance = db_instance
        self.user_connection = None
        self.load_schema = None;

class DataProduct:
    def __init__(self, product_id, source_id, collection_name = None, schema = None, source_path = None):
        self.product_id = product_id
        self.source_id = source_id
        self.collection_id = product_id
        self.collection_name = collection_name
        self.schema = schema
        self.source_path = source_path


def test_exists( sql, conn=None):
    try:
        if conn is None:
            conn = gb.sde_connection

        sde_conn = arcpy.ArcSDESQLExecute(conn)

        # rows = cursor.execute(sql).fetchall()
        exists = sde_conn.execute(sql)


        # Create a pandas DataFrame from the fetched data

        return exists;
    except Exception as e:
        print(f"Error: {e}")

def load_product_source_details() :

    try:
        logger.info("Retrieving data product details from RDBMS")
        sde_conn = arcpy.ArcSDESQLExecute(gb.sde_connection)
        where_clause = f"where collection_id = {gb.product.product_id} and source_id = {gb.product.source_id}"
        # where_clause = ""
        # Build the SQL query with WHERE clause
        sql = f"SELECT path, collection_schema, collection_name FROM meta.data_product_sources_view {where_clause}"

        # rows = cursor.execute(sql).fetchall()
        rows = sde_conn.execute(sql)
        # Create a pandas DataFrame from the fetched data
        df = pd.DataFrame(rows, columns=["path", "collection_schema", "collection_name"])
        first_row = df.iloc[0]
        gb.product.collection_name = first_row['collection_name']
        gb.product.schema = first_row['collection_schema'].lower()
        gb.load_schema = f"{gb.product.schema}_load"
        gb.product.source_path =first_row['path']
        logger.info(f"{gb.product.schema} : {gb.product.collection_name} : {gb.product.source_path}")
        gb.user_connection = f"{gb.sde_root}\{gb.load_schema}-{gb.db_env}.sde"
    except Exception as e:
        logger.error("Error Retrieving data product details from RDBMS", e)


def init_globals() -> Globals:
    logger.info("Started Load Process, Initializing")
    now = datetime.datetime.now()
    args = process_args()
    gb = Globals(now, args)
    logger.info(f"Loading Product data for {gb.product.product_id} Source {gb.product.source_id}")
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
    "--output_dir",
    type = str,
    help = "path to the directory where sde connection files are stored.",
    )
    parser.add_argument(
        "--sde_root",
        type=str,
        help="path to the directory where sde connection files are stored.",
    )
    parser.add_argument(
        "--staging_sde",
        type=str,
        help="catalog user sde connection prefix.",
    )
    parser.add_argument(
        "--db_database",
        type=str,
        help="egdb",
    )
    parser.add_argument(
        "--db_env",
        type=str,
        help="dev, stage, prod",
    )
    parser.add_argument(
        "--db_instance",
        type=str,
        help="sde db name",
    )
    parsed_args = parser.parse_args()
    args = vars(parsed_args)
    return args

def create_load_schema():


    logger.info(f"Checking if {gb.load_schema} Schema exists")
    test_sql = f"SELECT EXISTS(SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = '{gb.load_schema}')"

    exists = test_exists(test_sql)
    if not exists:
        logger.info(f"Creating { gb.load_schema} User and Schema ")
        arcpy.management.CreateDatabaseUser(
            input_database=gb.sde_connection,
            user_authentication_type="DATABASE_USER",
            user_name= gb.load_schema,
            user_password= gb.load_schema,
            role=gb.staging_sde,
            tablespace_name=""
        )


def create_user_connection( staged_env = 'dev'):
    logger.info(f"Checking if {gb.user_connection} connection file exists")
    out_name = f"{gb.load_schema}-{staged_env}"
    connection_file = os.path.join(gb.sde_root, out_name)
    sde_connect_file = f'{connection_file}.sde'
    if not os.path.exists(sde_connect_file):

        sde_connect_file = arcpy.management.CreateDatabaseConnection(
            out_folder_path=gb.sde_root,
            out_name=out_name,
            database_platform="POSTGRESQL",
            instance=gb.db_instance,
            account_authentication="DATABASE_AUTH",
            username=gb.load_schema,
            password=gb.load_schema,
            save_user_pass="SAVE_USERNAME",
            database=gb.db_database,
            # schema="",  This option only applies to Oracle databases that contain at least one user–schema geodatabase. The default value for this parameter is to use the sde schema geodatabase.
            version_type="TRANSACTIONAL",
            version="sde.DEFAULT",
            role=gb.staging_sde
        )
    return sde_connect_file
def main():

    global logger
    global gb

    logger = initialize_logger()
    gb = init_globals()

    load_product_source_details()
    create_load_schema()
    create_user_connection()
    logger.info("Completed Load Process")
if __name__ == "__main__":
    main()
