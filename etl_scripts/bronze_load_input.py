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
import requests
import arcpy
import logging
import sqlalchemy
from sqlalchemy import create_engine, text
import psycopg2
import datetime
import pandas as pd
from arcgis.features import FeatureLayerCollection, FeatureLayer


class Globals:
    def __init__(self, dts, args):
        formatted_dts = dts
        product_id = args["data_product_id"]
        source_id = args["source_id"]
        output_dir = args["output_dir"]
        sde_root = args["sde_root"]
        staging_sde = args["staging_sde"]
        db_database = args["db_database"]
        db_env = args["db_env"]
        db_instance = args["db_instance"]

        self.sde_connection = f"{sde_root}\{staging_sde}-{db_env}.sde"

        self.product_path = output_dir
        self.dts = formatted_dts
        self.product = DataProduct(product_id, source_id)
        self.sde_root = sde_root
        self.staging_sde = staging_sde
        self.db_database = db_database
        self.db_env = db_env
        self.db_instance = db_instance
        self.user_connection = None
        self.load_schema = None


class LoadHistory:
    def __init__(self, source_id, source_path, definition, json):
        self.source_id = source_id
        self.source_path = source_path
        self.load_datetime = datetime.datetime.now()
        self.load_status = 'INIT'
        self.source_description = definition["serviceDescription"]
        self.source_capabilities = definition["capabilities"]
        self.srid = definition["spatialReference"]["wkid"]
        self.definition = json
        # self.tables= [f"{l['id']}:{l['name']}" for l in definition["tables"]]
        # self.layers=[f"{l['id']}:{l['name']}:{l['type']}" for l in definition["layers"]]
        # self.relationships=[]

    def getData(self):
        return (self.source_id,
                self.source_path,
                self.load_datetime,
                self.load_status,
                self.source_description,
                self.source_capabilities,
                self.srid,
                self.definition)


class LoadHistoryItem:
    def __init__(self, load_id, source_id, source_path, records, definition, json):
        self.load_id = load_id
        self.source_id = source_id
        self.load_datetime = datetime.datetime.now()
        self.load_status = 'INIT'
        self.original_name = definition["name"]
        self.revised_name = ''
        self.item_path = source_path
        self.srid = ''
        self.last_seq = 1
        self.original_col_names = [l['name'] for l in definition["fields"]],
        self.revised_col_names = []
        self.original_col_types = [l['type'] for l in definition["fields"]],
        self.revised_col_types = []
        self.configs = json
        self.record_count = records

    def getData(self):
        return (self.load_id,
                self.original_name,
                self.revised_name,
                self.record_count,
                self.load_status,
                self.item_path,
                self.srid,
                self.last_seq,
                self.original_col_names,
                self.revised_col_names,
                self.original_col_types,
                self.revised_col_types,
                self.configs)


class ETLRecord:
    def __init__(self, source_id, step, status):
        self.source_id = source_id
        self.step = step
        self.status = status


class DataProduct:
    def __init__(self, product_id, source_id, collection_name=None, schema=None, source_path=None):
        self.product_id = product_id
        self.source_id = source_id
        self.collection_id = product_id
        self.collection_name = collection_name
        self.schema = schema
        self.source_path = source_path


class SQLAlchemyHandler(logging.Handler):
    def __init__(self, level: 0):
        super().__init__(level)
        self.engine = alchemy_engine
        self.sql = f"INSERT INTO bronze_staging.etl_control (source_id,run_datetime,step,status) VALUES (:source_id,:run_datetime,:status,:step)"

    def emit(self, record):

        try:
            insert_statement = text("""
                   INSERT INTO etl_control (source_id, run_datetime, status, step)
                   VALUES (:source_id, :run_datetime, :status, :step)
               """)
            values = {
                'source_id': record.etl.source_id,
                'run_datetime': datetime.datetime.now(),
                'status': record.etl.status,
                'step': record.etl.step
            }

            with self.engine.connect() as conn:
                conn.execute(insert_statement, values)
        except Exception as e:
            print(e)


class CustomFormatter(logging.Formatter):
    def __init__(self):
        self.source_id = None
        self.status = None
        self.step = None

    def format(self, record):
        return super().format(record)


# Create a filter to only log error-level messages
class DBFilter(logging.Filter):

    def __init__(self):
        print("Initializing filter")

    def filter(self):
        include = hasattr(self, "etl")
        return include


def test_exists(sql, conn=None):
    try:
        if conn is None:
            conn = gb.sde_connection

        sde_conn = arcpy.ArcSDESQLExecute(conn)
        exists = sde_conn.execute(sql)
        return exists;
    except Exception as e:
        print(f"Error: {e}")


def load_product_source_details():
    try:
        logger.info("Retrieving data product details from RDBMS")
        sde_conn = arcpy.ArcSDESQLExecute(gb.sde_connection)
        where_clause = f"where collection_id = {gb.product.product_id} and source_id = {gb.product.source_id}"
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
        gb.product.source_path = first_row['path']
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


def setup_etl_control():
    # PostgreSQL connection details
    try:
        # engine = create_engine("postgresql://scott:tiger@localhost/test")

        db_handler = SQLAlchemyHandler(0)
        db_handler.addFilter(DBFilter)
        logger.addHandler(db_handler)
    except Exception as e:
        logger.error(e)


def initialize_logger():
    logger = logging.getLogger(__name__)

    stream_handler = logging.StreamHandler()
    logger.setLevel(logging.DEBUG)
    logger.addHandler(stream_handler)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    stream_handler.setFormatter(formatter)
    # Add the filter to the DBHandler

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
        type=str,
        help="path to the directory where sde connection files are stored.",
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
        logger.info(f"Creating {gb.load_schema} User and Schema ")
        arcpy.management.CreateDatabaseUser(
            input_database=gb.sde_connection,
            user_authentication_type="DATABASE_USER",
            user_name=gb.load_schema,
            user_password=gb.load_schema,
            role=gb.staging_sde,
            tablespace_name=""
        )


def create_user_connection(staged_env='dev'):
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
        logger.info(f"Created connection file {sde_connect_file}")
    return sde_connect_file


def add_load_history_record(source_record, is_child=False):
    return_id = -1
    try:
        # Establish a connection to the PostgreSQL database
        conn = psycopg2.connect(
            dbname=gb.db_database,
            user=gb.staging_sde,
            password=gb.staging_sde,
            host=gb.db_instance
        )

        # Create a cursor object to interact with the database
        cur = conn.cursor()

        # Define the SQL insert statement
        insert_parent_query = """
             INSERT INTO load_history (source_id, source_path, load_datetime, load_status, source_description, 
             source_capabilities, srid,definition)
            VALUES( %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING load_id
        """

        insert_child_query = """
             INSERT INTO load_history_item (load_id, original_name, revised_name, feature_count, load_status, 
             item_path, srid, last_seq, original_col_names, revised_col_names, original_col_types, revised_col_types, configs)
             VALUES( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
             RETURNING item_id
        """
        if not is_child:
            record_data = source_record.getData()
            # Execute the insert statement
            cur.execute(insert_parent_query, record_data)
            load_id = cur.fetchone()[0]
            return_id = load_id
        else:
            record_data = source_record.getData()
            # Execute the insert statement
            cur.execute(insert_child_query, record_data)
            item_id = cur.fetchone()[0]
            return_id = item_id
        # Commit the transaction
        conn.commit()
    except Exception as e:
        logger.error(e)
    finally:
        # Close the    cursor and connection
        cur.close()
        conn.close()
        return return_id


def test_url_information(source, load_id=None, is_child=False):
    logger.info(f"Initiating query of data from url: {gb.product.source_path}")
    # layer_collection = FeatureLayerCollection(gb.product.source_path)
    response = requests.get(f"{source}?f=json")

    esrijson_data = json.loads(response.text)
    if not is_child:
        loadHistory = LoadHistory(gb.product.source_id, gb.product.source_path, esrijson_data, response.text)
        load_id = add_load_history_record(loadHistory)

        if "layers" in esrijson_data:
            for child in esrijson_data["layers"]:
                child_url = f"{gb.product.source_path}/{child['id']}"
                test_url_information(child_url, load_id, is_child=True)
        if "tables" in esrijson_data:
            for child in esrijson_data["tables"]:
                child_url = f"{gb.product.source_path}/{child['id']}"
                test_url_information(child_url, load_id, is_child=True)

    else:
        feature_count = int(arcpy.GetCount_management(source)[0])
        loadHistoryItem = LoadHistoryItem(load_id, gb.product.source_id, source, feature_count, esrijson_data, response.text)
        add_load_history_record(loadHistoryItem, is_child=True)
    logger.info(f"Done Initiating query of data from url: {gb.product.source_path}")


def load_url_to_sde():
    logger.info("Initiating load of table to sde")


def main():
    global logger
    global gb
    global alchemy_engine

    logger = initialize_logger()
    gb = init_globals()
    load_product_source_details()
    create_load_schema()
    alchemy_engine = sqlalchemy.create_engine(
        f'postgresql://{gb.staging_sde}:{gb.staging_sde}@{gb.db_instance}/{gb.db_database}')
    create_user_connection()
    setup_etl_control()
    logger.info("Initializing ETL Process", extra={"etl": ETLRecord(gb.product.source_id, "INIT", "RUNNNING")})
    test_url_information(gb.product.source_path)
    load_url_to_sde()
    logger.info("Completed Load Process")


if __name__ == "__main__":
    main()
