import logging
import argparse
import json
import datetime
import re
import os
import psycopg2
import pandas as pd
from types import SimpleNamespace
import arcpy

import boto3
from botocore.exceptions import ClientError
from sqlalchemy import create_engine


def create_catalog_connection(gb, staged_env='dev', connection_name=None):
    gb.logger.info(f"Checking if {gb.sde_connection} connection file exists")
    out_name = connection_name
    if out_name is None:
        out_name = f"{gb.configs.db_user}-{staged_env}"
    connection_file = os.path.join(gb.configs.sde_root, out_name)
    sde_connect_file = f'{connection_file}.sde'
    if os.path.exists(sde_connect_file):
        os.remove(sde_connect_file)

    sde_connect_file = arcpy.management.CreateDatabaseConnection(
        out_folder_path=gb.configs.sde_root,
        out_name=out_name,
        database_platform="POSTGRESQL",
        instance=gb.configs.db_ro_instance,
        account_authentication="DATABASE_AUTH",
        username='bronze_catalog',
        password=get_secret(gb, f"{staged_env}/user/bronze_catalog")["password"],
        save_user_pass="SAVE_USERNAME",
        database=gb.configs.db_database,
        # schema="",  This option only applies to Oracle databases that contain at least one user–schema geodatabase. The default value for this parameter is to use the sde schema geodatabase.
        version_type="TRANSACTIONAL",
        version="sde.DEFAULT",
        role='catalog'
    )
    gb.logger.info(f"Created connection file {sde_connect_file}")
    return f"{sde_connect_file}"

def create_sde_connection(gb, staged_env='dev'):
    gb.logger.info(f"Checking if {gb.sde_connection} connection file exists")
    out_name = f"{gb.configs.db_user}-{staged_env}"
    connection_file = os.path.join(gb.configs.sde_root, out_name)
    sde_connect_file = f'{connection_file}.sde'
    if os.path.exists(sde_connect_file):
        os.remove(sde_connect_file)

    sde_connect_file = arcpy.management.CreateDatabaseConnection(
        out_folder_path=gb.sde_root,
        out_name=out_name,
        database_platform="POSTGRESQL",
        instance=gb.configs.db_instance,
        account_authentication="DATABASE_AUTH",
        username=gb.configs.db_user,
        password=get_secret(gb, f"{staged_env}/egis/writer")["password"],
        save_user_pass="SAVE_USERNAME",
        database=gb.configs.db_database,
        # schema="",  This option only applies to Oracle databases that contain at least one user–schema geodatabase. The default value for this parameter is to use the sde schema geodatabase.
        version_type="TRANSACTIONAL",
        version="sde.DEFAULT",
        role='etl_writer'
    )
    gb.logger.info(f"Created connection file {sde_connect_file}")
    return sde_connect_file

def create_etl_connection(gb, staged_env='dev'):
    gb.logger.info(f"Checking if {gb.sde_connection} connection file exists")
    out_name = f"{gb.configs.db_user}-{staged_env}"
    connection_file = os.path.join(gb.configs.sde_root, out_name)
    sde_connect_file = f'{connection_file}.sde'
    if os.path.exists(sde_connect_file):
        os.remove(sde_connect_file)

    sde_connect_file = arcpy.management.CreateDatabaseConnection(
        out_folder_path=gb.configs.sde_root,
        out_name=out_name,
        database_platform="POSTGRESQL",
        instance=gb.configs.db_instance,
        account_authentication="DATABASE_AUTH",
        username=gb.configs.db_user,
        password=get_secret(gb, f"{staged_env}/egis/writer")["password"],
        save_user_pass="SAVE_USERNAME",
        database=gb.configs.db_database,
        # schema="",  This option only applies to Oracle databases that contain at least one user–schema geodatabase. The default value for this parameter is to use the sde schema geodatabase.
        version_type="TRANSACTIONAL",
        version="sde.DEFAULT",
        role='etl_writer'
    )
    gb.logger.info(f"Created connection file {sde_connect_file}")
    return sde_connect_file
# Set env, CRYPTOGRAPHY_OPENSSL_NO_LEGACY=true
def load_json_from_file(file_path, logger = None):
    config_json = None
    try:
        # Load the config
        with open(os.path.join(file_path)) as json_data:
            config_json = json.load(json_data)
    except Exception as e:
        if logger is not None:
            logger.error(f"Error Could not load  {file_path}", e)
        raise e
    return config_json

# ----------------------------- DataProduct -----------------------------
#  Used as Data Transfer Object for RDS Information about products and sources
class DataProduct:
    def __init__(self, product_id, source_id, collection_name=None, schema=None, source_path=None):
        self.product_id = product_id
        self.source_id = source_id
        self.collection_id = product_id
        self.collection_name = collection_name
        self.schema = schema
        self.source_path = source_path
# ----------------------------- END DataProduct -----------------------------


# ----------------------------- LoadHistory -----------------------------
# Used as Data Transfer Object for ETL Process's Load History Table
class LoadHistory:
    def __init__(self, source_id, definition):
        fc_json = json.dumps(dict(definition.properties))
        self.source_id = source_id
        self.source_path = definition.url
        self.start_datetime = datetime.datetime.now()
        self.end_datetime = None
        self.load_status = 'INIT'
        self.properties_json = fc_json
        self.load_id = None
        self.spatialReference = definition.properties.spatialReference
        # self.tables= [f"{l['id']}:{l['name']}" for l in definition["tables"]]
        # self.layers=[f"{l['id']}:{l['name']}:{l['type']}" for l in definition["layers"]]
        # self.relationships=[]

    def getData(self):
        return (self.source_id,
                self.source_path,
                self.start_datetime,
                self.load_status,
                self.properties_json)

    def getDict(self):
        return {"source_id": self.source_id,
                "source_path": self.source_path,
                "start_datetime": self.start_datetime,
                "end_datetime": self.end_datetime,
                "load_status": self.load_status,
                "properties_json": self.properties_json,
                "load_id": self.load_id}

    def persist(self,gb):
        self.load_id = insert_record(gb, self)

    def complete_load(self, gb, status):
        self.end_datetime = datetime.datetime.now()
        self.load_status = status
        update_record(self, gb, ["end_datetime", "load_status"])
# ----------------------------- END LoadHistory -----------------------------

# ----------------------------- LoadHistoryItem -----------------------------
# Used as Data Transfer Object for ETL Process's Load History Item Table
class LoadHistoryItem:
    def __init__(self, load_id, source_id, definition):
        fc_json = json.dumps(dict(definition.properties))
        self.load_id = load_id
        self.item_id = None
        self.source_id = source_id
        self.start_datetime = None
        self.end_datetime = None
        self.load_status = 'INIT'
        self.original_name = definition.properties.name
        temp_name = definition.properties.name.lower().replace("- ", "").replace(" ", "_")
        self.revised_name = re.sub(r"[()]", "", temp_name)
        self.item_path = definition.url
        self.srid = ''
        self.feature = definition
        self.isTable = definition.properties.type == 'Table'
        names = [l['name'] for l in definition.properties.fields]
        types = [l['type'] for l in definition.properties.fields]
        self.revised_col_names = [to_snake(l['name']) for l in definition.properties.fields]
        self.revised_col_types = []
        self.properties_json = fc_json
        self.estimated_feature_count = 0
        if hasattr(definition, "estimates"):
            if "count" in definition.estimates:
                self.estimated_feature_count = definition.estimates["count"]
        self.actual_feature_count = 0

    # load_id, revised_name, item_path, load_datetime, load_status, srid, revised_col_names,
    # revised_col_types, properties_json, estimated_feature_count
    def getData(self):
        return (self.load_id,
                self.revised_name,
                self.item_path,
                self.start_datetime,
                self.load_status,
                self.srid,
                self.revised_col_names,
                self.revised_col_types,
                self.properties_json,
                self.estimated_feature_count)

    def getDict(self):
        return {"load_id": self.load_id,
                "item_id": self.item_id,
                "revised_name": self.revised_name,
                "item_path": self.item_path,
                "load_status": self.load_status,
                "srid": self.srid,
                "revised_col_names": self.revised_col_names,
                "revised_col_types": self.revised_col_types,
                "properties_json": self.properties_json,
                "start_datetime": self.start_datetime,
                "end_datetime": self.end_datetime,
                "estimated_feature_count": self.estimated_feature_count,
                "actual_feature_count": self.actual_feature_count
                }

    def persist(self, gb):
        self.item_id = insert_record(gb, self)

    def update_status(self, gb, status):
        self.start_datetime = datetime.datetime.now()
        self.load_status = "LOADING"
        update_record(self, gb,["start_datetime", "load_status"])

    def complete_load(self, gb, count):
        self.end_datetime = datetime.datetime.now()
        self.load_status = "DONE"
        self.actual_feature_count = count
        update_record(self, gb,["end_datetime", "load_status", "actual_feature_count"])
# ----------------------------- END LoadHistoryItem -----------------------------

# ----------------------------- ETLRecord -----------------------------
# Used as Data Transfer Object for ETL Process's ETL control view
class ETLRecord:
    def __init__(self, source_id, step, status):
        self.source_id = source_id
        self.step = step
        self.status = status
        self.start_datetime = datetime.datetime.now()
        self.load_id = None
        self.etl_run_id = None
        self.end_datetime = None

    def getData(self):
        return (self.source_id,
                self.start_datetime,
                self.step,
                self.status)

    def getDict(self):
        return {"etl_run_id": self.etl_run_id,
                "source_id": self.source_id,
                "step": self.step,
                "status": self.status,
                "load_id": self.load_id,
                "start_datetime": self.start_datetime,
                "end_datetime": self.end_datetime}

    def initialize_etl_run( self, gb):
        self.etl_run_id = insert_record(gb, self)

    def complete_load(self, gb, status):
        self.step = 'COMPLETED'
        self.status = status
        self.end_datetime = datetime.datetime.now()
        update_record( self, gb, ["load_id", "step", "status", "end_datetime"])

    def update_load(self, gb, step):
        self.step = step
        self.start_datetime = datetime.datetime.now()
        update_record( self, gb, ["load_id", "step", "start_datetime"])

# ----------------------------- END ETLRecord -----------------------------


def insert_record(gb, source_record):
    return_id = -1
    with psycopg2.connect(dbname=gb.configs.db_database,
                          user=gb.configs.db_user,
                          password=get_secret(gb, f"{gb.configs.db_env}/egis/writer")["password"],
                          host=gb.configs.db_instance) as conn:
        with conn.cursor() as cur:
            query = None
            if isinstance(source_record, LoadHistory):
                # Define the SQL insert statement
                query = """
                     INSERT INTO load_history(source_id, source_path, start_datetime, load_status, properties_json)
                     VALUES( %s, %s, %s, %s, %s)
                    RETURNING load_id
                """
            elif isinstance(source_record, LoadHistoryItem):
                query = """
                     INSERT INTO load_history_item(load_id, revised_name, item_path, start_datetime, load_status, 
                     srid, revised_col_names,revised_col_types, properties_json, estimated_feature_count)
                     VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                     RETURNING item_id
                """
            elif isinstance(source_record, ETLRecord):
                query = """
                     INSERT INTO etl_control(source_id, start_datetime, step, status) VALUES ( %s, %s, %s, %s)
                     RETURNING etl_run_id
                """
            if query is not None:
                try:
                    record_data = source_record.getData()
                    # Execute the insert statement
                    cur.execute(query, record_data)
                    return_id = cur.fetchone()[0]
                except Exception as e:
                    gb.logger.error(f"Exception persisting {type(source_record)} record", e)
    return return_id




def update_record(source_record, gb, update_fields):
    return_id = -1
    with psycopg2.connect(dbname=gb.configs.db_database,
                          user=gb.configs.db_user,
                          password=get_secret(gb, f"{gb.configs.db_env}/egis/writer")["password"],
                          host=gb.configs.db_instance) as conn:
        with conn.cursor() as cur:
            query = None
            source_dict = source_record.getDict()
            updateable_list = [f"{l} = %s" for l in update_fields]
            updateable_values = [f"{source_dict[l]}" for l in update_fields]

            id = None
            if isinstance(source_record, LoadHistory):
                # Define the SQL insert statement
                id = source_record.load_id
                query = f"""
                         UPDATE load_history
                         SET  {",".join(updateable_list)}
                         WHERE load_id = %s                        
                    """
            elif isinstance(source_record, LoadHistoryItem):
                id = source_record.item_id
                query = f"""
                        UPDATE load_history_item
                         SET  {",".join(updateable_list)}
                        WHERE item_id = %s
                    """
            elif isinstance(source_record, ETLRecord):
                id = source_record.etl_run_id
                query = f"""
                        UPDATE etl_control
                         SET  {",".join(updateable_list)}
                        WHERE etl_run_id=%s;
                    """
            if query is not None:
                try:
                    record_data = source_record.getData()
                    # Execute the insert statement
                    cur.execute(query, updateable_values + [id])

                except Exception as e:
                    gb.logger.error(f"Exception updating {type(source_record)} record", e)
    return return_id


def get_data(gb, table_name):
    # Create the engine without the password
    # engine = create_engine('postgresql://user@host:port/database')

    df = None
    try:
        # Connect to the database with the password
        engine = create_engine(f'postgresql://{gb.configs.db_user}:{get_secret(gb, f"{gb.db_env}/egis/writer")["password"]}@{gb.db_instance}/{gb.db_database}')
        # engine = create_engine('postgresql://user:password@host:port/database')

        # engine = create_engine(f'postgresql+psycopg2://{db_username}:{db_password}@{db_host}:{db_port}/{db_name}')

        # Load data from a SQL query
        df = pd.read_sql_query(f"select * from {table_name} order by data_product_id", engine)
    except Exception as e:
        gb.logger.info(f"Error retrieving data from {table_name}",e)
    print(df)
    return df



def initialize_logger(log_file=None, debug=False):
    logger = logging.getLogger(__name__)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    logger.setLevel(logging.INFO)
    if debug:
        stream_handler = logging.StreamHandler()
        stream_handler.setFormatter(formatter)
        logger.setLevel(logging.DEBUG)
        logger.addHandler(stream_handler)
    if log_file is not None:
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

    return logger

def process_args_load():
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
    parser.add_argument(
        "--aws_region",
        type=str,
        help="aws_region",
    )
    parsed_args = parser.parse_args()
    args = vars(parsed_args)
    return args


def process_args_publish():
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
        "--sde_root",
        type=str,
        help="path to the directory where sde connection files are stored.",
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
    parser.add_argument(
        "--aws_region",
        type=str,
        help="aws_region",
    )
    parsed_args = parser.parse_args()
    args = vars(parsed_args)
    return SimpleNamespace(**args)



def is_pascal_case(string):
    return not string.isupper() and bool(re.match(r'^[A-Z][a-zA-Z0-9]*$', string))


def to_snake(string):
    if is_pascal_case(string):
        val = re.sub(r'(?<!^)([A-Z])', r'_\1', string.strip()).lower()
    else:
        val = re.sub(r'\s+', '_', re.sub(r'\W+', ' ', string.strip()).strip()).lower()

    return val

def get_secret(gb, secret_name):

    # secret_name = "dev/egis/writer"
    # region_name = "us-gov-west-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=gb.configs.aws_region
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response['SecretString']
    return json.loads(secret)