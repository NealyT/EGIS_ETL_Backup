"""
bronze_load_input.py
Project: USACE: BAH: EGIS Authoritative Source Repository
Date: August 2024
Auther: Nealie Thompson
"""

import os
import json
import re
import psycopg2
import datetime
import pandas as pd
import sys
import subprocess

from arcgis.features import FeatureLayerCollection, FeatureLayer
from etl_scripts.bronze.utils import *

def postGIS(product, file_path, table_name, host, dbname, user, password):
    ogr_location = r"C:\Program Files\QGIS 3.38.0\bin\ogr2ogr.exe"
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

class LoadGlobals:
    def __init__(self, args, configs):
        now = datetime.datetime.now()
        formatted_dts = now
        sde_root = configs["sde_root"]
        loader_sde = configs["loader_sde"]
        db_env = configs["db_env"]

        self.sde_connection = f"{sde_root}\{loader_sde}-{db_env}.sde"
        self.product_path = configs["output_dir"]
        self.dts = formatted_dts
        self.product = LoadDataProduct(args["data_product_id"], args["source_id"])
        self.sde_root = sde_root
        self.loader_sde = loader_sde
        self.db_database = configs["db_database"]
        self.db_env = db_env
        self.db_instance = configs["db_instance"]
        self.user_connection = None
        self.load_schema = None
        self.etl_record = None
        self.load_history = None
        self.load_history_items = []
        self.catalog_role = configs["catalog_role"]
        self.entities = None
        self.mapped_columns = None


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
        # self.tables= [f"{l['id']}:{l['name']}" for l in definition["tables"]]
        # self.layers=[f"{l['id']}:{l['name']}:{l['type']}" for l in definition["layers"]]
        # self.relationships=[]

    # load_history(source_id, source_path, load_datetime, load_status, properties_json)
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

    def persist(self):
        self.load_id = insert_record(self)

    def complete_load(self, status):
        self.end_datetime = datetime.datetime.now()
        self.load_status = status
        update_record(self, ["end_datetime", "load_status"])


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
        self.revised_name = definition.properties.name.lower().replace("- ", "").replace(" ", "_")
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

    def persist(self):
        self.item_id = insert_record(self)

    def update_status(self, status):
        self.start_datetime = datetime.datetime.now()
        self.load_status = "LOADING"
        update_record(self, ["start_datetime", "load_status"])

    def complete_load(self, count):
        self.end_datetime = datetime.datetime.now()
        self.load_status = "DONE"
        self.actual_feature_count = count
        update_record(self, ["end_datetime", "load_status", "actual_feature_count"])


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

    def initialize_etl_run(self):
        self.etl_run_id = insert_record(self)

    def complete_load(self, status):
        self.step = 'COMPLETED'
        self.status = status
        self.end_datetime = datetime.datetime.now()
        update_record(self, ["load_id", "step", "status", "end_datetime"])

    def update_load(self, step):
        self.step = step
        self.start_datetime = datetime.datetime.now()
        update_record(self, ["load_id", "step", "start_datetime"])


class LoadDataProduct:
    def __init__(self, product_id, source_id, collection_name=None, schema=None, source_path=None):
        self.product_id = product_id
        self.source_id = source_id
        self.collection_id = product_id
        self.collection_name = collection_name
        self.schema = schema
        self.source_path = source_path


def is_pascal_case(string):
    return not string.isupper() and bool(re.match(r'^[A-Z][a-zA-Z0-9]*$', string))


def to_snake(string):
    if is_pascal_case(string):
        val = re.sub(r'(?<!^)([A-Z])', r'_\1', string.strip()).lower()
    else:
        val = re.sub(r'\s+', '_', re.sub(r'\W+', ' ', string.strip()).strip()).lower()

    return val


def test_exists(sql, conn=None):
    try:
        if conn is None:
            conn = gb.sde_connection

        sde_conn = arcpy.ArcSDESQLExecute(conn)
        exists = sde_conn.execute(sql)
        return exists
    except Exception as e:
        logger.error(f"Error: {e}")


def load_product_source_details():
    try:
        logger.info("Retrieving data product details from RDBMS")
        sde_conn = arcpy.ArcSDESQLExecute(gb.sde_connection)
        where_clause = f"where collection_id = {gb.product.product_id} and source_id = {gb.product.source_id}"
        # Build the SQL query with WHERE clause
        sql = f"SELECT path, collection_schema, collection_name FROM meta.data_product_sources_view {where_clause}"
        rows = sde_conn.execute(sql)

        df = pd.DataFrame(rows, columns=["path", "collection_schema", "collection_name"])
        first_row = df.iloc[0]

        gb.product.collection_name = first_row['collection_name']
        gb.product.schema = first_row['collection_schema'].lower()
        gb.load_schema = gb.product.schema
        gb.product.source_path = first_row['path']
        gb.user_connection = f"{gb.sde_root}\{gb.load_schema}-{gb.db_env}.sde"

        where_clause = f"where table_schema = '{gb.product.schema}'"
        sql = f"SELECT distinct column_name, column_name_simple, mapped_column_name FROM etl_loader.column_mapping {where_clause}"
        rows = sde_conn.execute(sql)
        try:
            df = pd.DataFrame(rows, columns=["column_name", "column_name_simple", "mapped_column_name"])
            column_dict = {}
            for index, row in df.iterrows():
                column_dict[row["column_name"]] = row["mapped_column_name"]
                if row["column_name_simple"] not in column_dict:
                    column_dict[row["column_name_simple"]] = row["mapped_column_name"]

            gb.mapped_columns = column_dict
        except Exception as e:
            logger.info("No column mapping for {gb.product.schema}")
        logger.info(f"{gb.product.schema} : {gb.product.collection_name} : {gb.product.source_path}")

    except Exception as e:
        logger.error("Error Retrieving data product details from RDBMS", e)


def create_load_schema():
    logger.info(f"Checking if {gb.load_schema} Schema exists")
    # test_sql = f"SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = '{gb.load_schema}')"
    test_sql = f"SELECT EXISTS(SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = '{gb.load_schema}')"

    exists = test_exists(test_sql)
    if not exists:
        logger.info(f"Creating {gb.load_schema} User and Schema ")
        arcpy.management.CreateDatabaseUser(
            input_database=gb.sde_connection,
            user_authentication_type="DATABASE_USER",
            user_name=gb.load_schema,
            user_password=gb.load_schema,
            role=gb.catalog_role
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
            role=gb.catalog_role
        )
        logger.info(f"Created connection file {sde_connect_file}")
    return sde_connect_file


def update_record(source_record, update_fields):
    return_id = -1
    with psycopg2.connect(dbname=gb.db_database, user=gb.loader_sde, password=gb.loader_sde,
                          host=gb.db_instance) as conn:
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
                    logger.error(f"Exception updating {type(source_record)} record", e)
    return return_id


def insert_record(source_record):
    return_id = -1
    with psycopg2.connect(dbname=gb.db_database, user=gb.loader_sde, password=gb.loader_sde,
                          host=gb.db_instance) as conn:
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
                    logger.error(f"Exception persisting {type(source_record)} record", e)
    return return_id


# Recursive method that inserts records into load_history (when load_id is None)
# or load_history_item for feature classes and tables
def initialize_load_history(entity=None, load_id=None):
    # entity is None only when initiated from main method
    if entity is None:
        # Test if schema exists, if not one will be created
        create_load_schema()
        # Test if connection file exists, if not one will be created
        create_user_connection()

        logger.info(f"Initiating query of data from url: {gb.product.source_path}")

        if gb.product.source_path.lower().endswith('.gpkg'):
            entity = FeatureLayerCollection()
            for feature_class in arcpy.ListFeatureClasses(gb.product.source_path):
                # Export the feature class to the output path
                flayer = FeatureLayer(feature_class.name,container = entity)
                arcpy.conversion.ExportFeatures(gb.product.source_path + "/" + feature_class.name,flayer)
        else:
            entity = FeatureLayerCollection(gb.product.source_path)

        gb.load_history = LoadHistory(gb.product.source_id, entity)
        gb.load_history.persist()
        gb.etl_record.load_id = gb.load_history.load_id
        gb.etl_record.update_load('PRE_LOAD')

        # Number of entities in general should be # of feature classes + # of tables
        max_id = len(entity.layers) + len(entity.tables)

        # However, it's possible some layers and tables removed, so need to verify maximum id
        # which should be largest size of entity list
        for child in entity.layers:
            if child.properties.id > max_id:
                max_id = child.properties.id
        for child in entity.tables:
            if child.properties.id > max_id:
                max_id = child.properties.id

        # Initialize a sparse array of entities, using max_id as size of array, all values initialized to None
        gb.entities = [None] * (max_id + 1)
        # Load each entity
        for child in entity.layers:
            initialize_load_history(child, gb.load_history.load_id)
        for child in entity.tables:
            initialize_load_history(child, gb.load_history.load_id)

    else:
        logger.info(f"Initiating query of data from url: {entity.url}")
        lhi = LoadHistoryItem(gb.load_history.load_id, gb.product.source_id, entity)
        lhi.persist()
        gb.entities[entity.properties.id] = lhi

    return entity


def load_entity_to_sde(item):
    logger.info(f"Loading {item.revised_name} into SDE")
    output_fc = f"{gb.user_connection}/{item.revised_name}"
    # Field mapping
    field_mapping = arcpy.FieldMappings()
    fields = item.feature.properties.fields

    try:
        if arcpy.Exists(output_fc):
            # arcpy.management.Rename(output_fc,f"{item.revised_name}_1")
            arcpy.management.Delete(output_fc)
        item.update_status("LOADING")
        if item.isTable:
            arcpy.conversion.ExportTable(item.item_path, output_fc)

        else:
            arcpy.conversion.ExportFeatures(item.item_path, output_fc)

        arcpy.AddGlobalIDs_management(output_fc)
        # Save Following Code for silver?
        # for index, f in enumerate(fields):
        #     old_name = f.name
        #     revised_name = item.revised_col_names[index]
        #     simplified_name = re.sub(r'[^a-zA-Z0-9]', '', revised_name)
        #     if gb.mapped_columns is not None:
        #         if simplified_name in gb.mapped_columns:
        #             revised_name = gb.mapped_columns[simplified_name]
        #         elif revised_name in gb.mapped_columns:
        #             revised_name = gb.mapped_columns[revised_name]
        #
        #     if old_name != revised_name:
        #         try:
        #             arcpy.management.AlterField(output_fc, old_name, revised_name)
        #         except Exception as e:
        #             logger.info(f"Error changing field {old_name} to {revised_name}")

        item.complete_load(int(arcpy.management.GetCount(output_fc)[0]))
        logger.info(f"Sucessfully Loaded {item.revised_name} into SDE")

    except Exception as e:
        logger.error(e)


def cleanup():
    parameters = (gb.catalog_role,
                  'bronze_catalog',
                  gb.product.schema,
                  True)  # Tuple of parameters, if any

    try:
        arcpy.env.workspace = gb.sde_connection

        # Execute the stored procedure
        cursor = arcpy.da.ExecuteCursor(arcpy.ArcSDESQLExecute('drop_schema_owner', parameters))

    except Exception as e:
        logger.error("Error removing role", e)


# load_sde loops through array of entities set on global and loads each
def load_sde():
    try:
        logger.info("Initiating load of table to sde")
        gb.etl_record.update_load('LOADING')
        for child in gb.entities:
            if child is not None:  # Array might be sparse
                load_entity_to_sde(child)
        gb.load_history.complete_load("COMPLETED")
        gb.etl_record.complete_load("SUCCESS")
    except Exception as e:
        gb.load_history.complete_load("FAILED")
        gb.etl_record.complete_load("FAIL")
        logger.error('Loading failed', e)


def main():
    # Initialize globals
    global logger
    global gb
    now = datetime.datetime.now()
    formatted_date = now.strftime('%Y%m%d%H%M%S')

    args = process_args_load()
    log_dir = args["log_dir"]
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"{formatted_date}_load.log")
    logger = initialize_logger(log_file, debug=True)
    config_json = None
    try:
        # Load the config
        with open(os.path.join(args["config_file"])) as json_data:
            config_json = json.load(json_data)
    except Exception as e:
        logger.error(f"Error Could not load  {gb.cfg_file}", e)
        sys.exit()

    gb = LoadGlobals(args, config_json)

    # Retrieve product and source data from RDBMS
    load_product_source_details()


    output_gdb = arcpy.management.CreateFileGDB(
        out_folder_path=gb.sde_root,
        out_name=f"{gb.product.schema}.gdb"
    )
    gb.user_connection = output_gdb
    # Initialize an ETLRecord instance to manage updates
    gb.etl_record = ETLRecord(gb.product.source_id, "INIT", "RUNNING")

    # Initialize etl run
    gb.etl_record.initialize_etl_run()

    # Create load_history and load_history_item records, populate gb.entities array
    # with items that will get loaded into SDE
    fc = initialize_load_history()

    # Begin loading data into SDE for entire feature collection
    load_sde()
    logger.info("Completed Load Process")

if __name__ == "__main__":
    main()
