"""
load_source.py
Project: USACE: BAH: EGIS Authoritative Source Repository
Date: August 2024
Auther: Nealie Thompson
"""
import arcpy
from arcgis.features import FeatureLayerCollection, FeatureLayer
import etl_scripts.bronze.utils as egis_utils
import os
import datetime
import pandas as pd
import sys



class Globals:
    def __init__(self, args, configs,logger):
        now = datetime.datetime.now()
        formatted_dts = now
        sde_root = configs["sde_root"]
        db_user = configs["db_user"]
        db_env = configs["db_env"]

        self.sde_connection = f"{sde_root}\{db_user}-{db_env}.sde"
        self.dts = formatted_dts
        self.product = egis_utils.DataProduct(args["data_product_id"], args["source_id"])
        self.sde_root = sde_root
        self.db_user = configs["db_user"]
        self.db_database = configs["db_database"]
        self.db_env = configs["db_env"]
        self.db_instance = configs["db_instance"]
        self.user_connection = None
        self.load_schema = None
        self.etl_record = None
        self.load_history = None
        self.load_history_items = []
        self.catalog_role = configs["catalog_role"]
        self.entities = None
        self.mapped_columns = None
        self.logger = logger
        self.aws_region = args["aws_region"]
        self.etl_writer = args["aws_ss_etl"]

def test_exists(sql, conn=None):
    try:
        if conn is None:
            conn = gb.sde_connection

        sde_conn = arcpy.ArcSDESQLExecute(conn)
        exists = sde_conn.execute(sql)
        return exists
    except Exception as e:
        gb.logger.error(f"Error: {e}")


def load_product_source_details():
    try:
        create_sde_connection(staged_env='dev')
        gb.logger.info("Retrieving data product details from RDBMS")
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

        # where_clause = f"where table_schema = '{gb.product.schema}'"
        # sql = f"SELECT distinct column_name, column_name_simple, mapped_column_name FROM etl_loader.column_mapping {where_clause}"
        # rows = sde_conn.execute(sql)
        # try:
        #     df = pd.DataFrame(rows, columns=["column_name", "column_name_simple", "mapped_column_name"])
        #     column_dict = {}
        #     for index, row in df.iterrows():
        #         column_dict[row["column_name"]] = row["mapped_column_name"]
        #         if row["column_name_simple"] not in column_dict:
        #             column_dict[row["column_name_simple"]] = row["mapped_column_name"]
        #
        #     gb.mapped_columns = column_dict
        # except Exception as e:
        #     gb.logger.info("No column mapping for {gb.product.schema}")
        gb.logger.info(f"{gb.product.schema} : {gb.product.collection_name} : {gb.product.source_path}")

    except Exception as e:
        gb.logger.error("Error Retrieving data product details from RDBMS", e)


def create_load_schema():
    gb.logger.info(f"Checking if {gb.load_schema} Schema exists")
    # test_sql = f"SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = '{gb.load_schema}')"
    test_sql = f"SELECT EXISTS(SELECT 1 FROM pg_catalog.pg_namespace WHERE nspname = '{gb.load_schema}')"

    exists = test_exists(test_sql)
    if not exists:
        gb.logger.info(f"Creating {gb.load_schema} User and Schema ")
        arcpy.management.CreateDatabaseUser(
            input_database=gb.sde_connection,
            user_authentication_type="DATABASE_USER",
            user_name=gb.load_schema,
            user_password=gb.load_schema,
            role=gb.catalog_role
        )


def create_user_connection(staged_env='dev'):
    gb.logger.info(f"Checking if {gb.user_connection} connection file exists")
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
        gb.logger.info(f"Created connection file {sde_connect_file}")
    return sde_connect_file

def create_sde_connection(staged_env='dev'):
    gb.logger.info(f"Checking if {gb.sde_connection} connection file exists")
    out_name = f"{gb.db_user}-{staged_env}"
    connection_file = os.path.join(gb.sde_root, out_name)
    sde_connect_file = f'{connection_file}.sde'
    if os.path.exists(sde_connect_file):
        os.remove(sde_connect_file)

    sde_connect_file = arcpy.management.CreateDatabaseConnection(
        out_folder_path=gb.sde_root,
        out_name=out_name,
        database_platform="POSTGRESQL",
        instance=gb.db_instance,
        account_authentication="DATABASE_AUTH",
        username=gb.db_user,
        password=egis_utils.get_secret(gb, f"{staged_env}/egis/writer")["password"],
        save_user_pass="SAVE_USERNAME",
        database=gb.db_database,
        # schema="",  This option only applies to Oracle databases that contain at least one user–schema geodatabase. The default value for this parameter is to use the sde schema geodatabase.
        version_type="TRANSACTIONAL",
        version="sde.DEFAULT",
        role='etl_writer'
    )
    gb.logger.info(f"Created connection file {sde_connect_file}")
    return sde_connect_file

# Recursive method that inserts records into load_history (when load_id is None)
# or load_history_item for feature classes and tables
def initialize_load_history(gb, entity=None):
    # entity is None only when initiated from main method
    if entity is None:
        # Test if schema exists, if not one will be created
        create_load_schema()
        # Test if connection file exists, if not one will be created
        create_user_connection()

        gb.logger.info(f"Initiating query of data from url: {gb.product.source_path}")

        if gb.product.source_path.lower().endswith('.gpkg'):
            entity = FeatureLayerCollection()
            for feature_class in arcpy.ListFeatureClasses(gb.product.source_path):
                # Export the feature class to the output path
                flayer = FeatureLayer(feature_class.name, container=entity)
                arcpy.conversion.ExportFeatures(gb.product.source_path + "/" + feature_class.name, flayer)
        else:
            entity = FeatureLayerCollection(gb.product.source_path)


        gb.load_history = egis_utils.LoadHistory(gb.product.source_id, entity)
        gb.load_history.persist(gb)
        gb.etl_record.load_id = gb.load_history.load_id
        gb.etl_record.update_load(gb, 'PRE_LOAD')

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
            initialize_load_history(gb, child)
        for child in entity.tables:
            initialize_load_history(gb, child)

    else:
        gb.logger.info(f"Initiating query of data from url: {entity.url}")
        lhi = egis_utils.LoadHistoryItem(gb.load_history.load_id, gb.product.source_id, entity)
        lhi.persist(gb)
        gb.entities[entity.properties.id] = lhi

    return entity


def move_to_egdb_try1(input_gdb):
    # DOES NOT WORK becausse of gb.product.schema
    arcpy.env.workspace = input_gdb
    fcs = arcpy.ListFeatureClasses()
    for fc in fcs:
        input_fc = f"{input_gdb}\{fc}"
        output_fc = f"{gb.sde_connection}\{gb.product.schema}.{fc}"
        if arcpy.Exists(output_fc):
            arcpy.DeleteFeatures_management(output_fc)
            arcpy.Append_management(input_fc, output_fc, "NO_TEST")
        else:
            arcpy.CopyFeatures_management(input_fc, output_fc)
        gb.logger.info(f"Created {output_fc}")

def move_to_egdb(input_gdb):
    # List all feature classes in the input file geodatabase
    arcpy.env.workspace = input_gdb
    feature_classes = arcpy.ListFeatureClasses()

    # Create a list to hold the input feature classes
    input_fc_list = []

    # Build the input feature class list with full paths
    for fc in feature_classes:
        input_fc = os.path.join(input_gdb, fc)
        input_fc_list.append(input_fc)

    # Use FeatureClassToGeodatabase to copy the feature classes to the SDE
    if input_fc_list:  # Check if the list is not empty
        arcpy.FeatureClassToGeodatabase_conversion(input_fc_list, gb.sde_connection)
        print("Feature classes copied to SDE successfully.")
    else:
        print("No feature classes found in the input file geodatabase.")

def load_all_to_fdb( items):
    # Create a new file geodatabase
    revised_name = gb.product.collection_name.replace(" ","_")
    path = f"D:\data\{gb.product.schema}"
    gdb_name= f"{revised_name}.gdb"
    if not os.path.exists(path):
        os.makedirs(path)
    # Path to the new geodatabase
    gdb_path = f"{path}\\{gdb_name}"
    if arcpy.Exists(gdb_path):
        # If it exists, delete it
        arcpy.Delete_management(gdb_path)
        print(f"Deleted existing geodatabase: {gdb_path}")

    arcpy.CreateFileGDB_management(path, gdb_name)
    # Use FeatureClassToGeodatabase_conversion to move all layers at once
    # urls = [i.item_path for i in items]
    for item in items:
        load_entity_to_db_container(item, gdb_path)



    # Import the file geodatabase as a schema
    # move_to_egdb(gdb_path)
    return gdb_path

def load_entity_to_db_container(item, output_fc):
    gb.logger.info(f"Loading {item.revised_name} into {output_fc}, ({item.estimated_feature_count} features)")
    # Specify the WKID
    wkid = 4326
    # item.feature.properties.srid  # Replace with the desired WKID
    # gb.load_history.spatialReference

    try:
        isGDB = len(os.path.splitext(output_fc))>0
        if isGDB:
            arcpy.env.workspace = output_fc
        item.update_status(gb,"LOADING")
        if item.isTable:
            arcpy.conversion.ExportTable(item.item_path, output_fc)
            arcpy.AddGlobalIDs_management(output_fc)
        else:
            desc = arcpy.Describe(item.item_path)
            spatial_ref = desc.spatialReference
            gb.logger.info(f"{item.revised_name} Spatial Reference Name: {spatial_ref.name}, WKID: {spatial_ref.factoryCode}")
            try:
                arcpy.conversion.ExportFeatures(item.item_path, output_fc)
                arcpy.AddGlobalIDs_management(output_fc)
            except Exception as ee:
                gb.logger.info(f"ExportFeatures failed for {item.revised_name}, trying alternative, conversion")
                try:
                    if isGDB:
                        arcpy.FeatureClassToGeodatabase_conversion(item.item_path, output_fc)
                        fcs = arcpy.ListFeatureClasses()
                        new_fc = fcs[-1]
                        new_fc_path = f"{output_fc}\\{new_fc}"
                        arcpy.Rename_management(new_fc_path, item.revised_name)
                        fcs = arcpy.ListFeatureClasses()
                        arcpy.AddGlobalIDs_management(fcs[-1])
                except Exception as e:
                    gb.logger.info(f"Error creating geodatabase, {e}", e)


        item.complete_load(gb, int(arcpy.management.GetCount(output_fc)[0]))
        gb.logger.info(f"Sucessfully Loaded {item.revised_name} into SDE")

    except Exception as e:
        gb.logger.error(e)


def load_entity_to_sde(item):
    gb.logger.info(f"Loading {item.revised_name} into SDE")
    output_fc = f"{gb.user_connection}/{item.revised_name}"
    # Field mapping
    field_mapping = arcpy.FieldMappings()
    fields = item.feature.properties.fields
    # Specify the WKID
    wkid = 4326
    # item.feature.properties.srid  # Replace with the desired WKID
    # gb.load_history.spatialReference
    try:
        if arcpy.Exists(output_fc):
            # arcpy.management.Rename(output_fc,f"{item.revised_name}_1")
            arcpy.management.Delete(output_fc)
        item.update_status(gb,"LOADING")
        if item.isTable:
            arcpy.conversion.ExportTable(item.item_path, output_fc)

        else:
            desc = arcpy.Describe(item.item_path)
            spatial_ref = desc.spatialReference
            print(f"Spatial Reference Name: {spatial_ref.name}, WKID: {spatial_ref.factoryCode}")

            ## TO_DO: Recreation Areas had 0 - Investigate further
            if spatial_ref.factoryCode <= 0:
                layer = FeatureLayer(item.item_path)
                features = layer.query(where="1=1", out_sr=4326)
                features.save(gb.user_connection,item.revised_name)
            else:
                arcpy.conversion.ExportFeatures(item.item_path, output_fc)
        ## TO_DO: Test if global id exists
        arcpy.AddGlobalIDs_management(output_fc)

        ## TO_DO: Do we support simple mapping here?
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

        item.complete_load(gb, int(arcpy.management.GetCount(output_fc)[0]))
        gb.logger.info(f"Sucessfully Loaded {item.revised_name} into SDE")

    except Exception as e:
        gb.logger.error(e)


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
        gb.logger.error("Error removing role", e)

def test_deltas():
    gdb_path= load_all_to_fdb(gb.entities)
    file_name, file_extension = os.path.splitext(gdb_path)
    prev_gdb_path = f"{file_name}_Archived.gdb"
    arcpy.env.workspace = prev_gdb_path
    feature_classes = arcpy.ListFeatureClasses()
    for item in gb.entities:
        current_layer = gdb_path + "/" + item.revised_name
        sdf = pd.DataFrame.spatial.from_featureclass(current_layer)
        print(sdf.head())
        try:
            prev_layer = prev_gdb_path + "/" + item.revised_name
            gdf =  pd.DataFrame.spatial.from_featureclass(prev_layer)
            print(gdf.head())
            # Equality comparison
            if sdf.equals(gdf):
                print("DataFrames are equal")
            else:
                # comparison = sdf.compare(gdf)
                print("DataFrames are not equal")
        except Exception as e:
            print(e)


# load_sde loops through array of entities set on global and loads each
def load_sde():
    try:
        gb.logger.info("Initiating load of table to sde")
        gb.etl_record.update_load(gb, 'LOADING')


        for child in gb.entities:
            if child is not None:  # Array might be sparse
                load_entity_to_sde(child)
        gb.load_history.complete_load(gb,"COMPLETED")
        gb.etl_record.complete_load(gb,"SUCCESS")
    except Exception as e:
        gb.load_history.complete_load(gb,"FAILED")
        gb.etl_record.complete_load(gb, "FAIL")
        gb.logger.error('Loading failed', e)

def init():
    global gb
    now = datetime.datetime.now()
    formatted_date = now.strftime('%Y%m%d%H%M%S')
    args = egis_utils.process_args_load()
    log_dir = args["log_dir"]
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"{formatted_date}_load.log")
    logger = egis_utils.initialize_logger(log_file, debug=True)
    try:
        config_json = egis_utils.load_json_from_file(args["config_file"], logger)
    except Exception as e:
        sys.exit(1)

    gb = Globals(args, config_json, logger)

def main():
    init()
    # Retrieve product and source data from RDBMS
    load_product_source_details()

    # Initialize an ETLRecord instance to manage updates
    gb.etl_record = egis_utils.ETLRecord(gb.product.source_id, "INIT", "RUNNING")

    # Initialize etl run
    gb.etl_record.initialize_etl_run(gb)

    # Create load_history and load_history_item records, populate gb.entities array
    # with items that will get loaded into SDE
    fc = initialize_load_history(gb)

    # Remove any entry entries in the entities array
    gb.entities = [x for x in gb.entities if x is not None]
    # Begin loading data into SDE for entire feature collection
    test_deltas()
    load_sde()
    gb.logger.info("Completed Load Process")

if __name__ == "__main__":
    main()
