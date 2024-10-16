from arcgis.gis import GIS
import os
import sys
import datetime
import json
import shutil
from etl_scripts.bronze.utils import *
from arcgis.gis import ItemProperties, ItemTypeEnum

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
        # self.product = LoadDataProduct(args["data_product_id"], args["source_id"])
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

def create_gdb(schema, o):

    if arcpy.Exists(o):
        # Delete the geodatabase
        arcpy.Delete_management(o)
        print("Geodatabase deleted successfully.")
    else:
        print("Geodatabase does not exist.")

    output_gdb = arcpy.management.CreateFileGDB(
        out_folder_path=gb.sde_root,
        out_name=f"{schema}.gdb"
    )

    sde_connection = f"{gb.sde_root}\server_connection.sde"

    arcpy.env.workspace = sde_connection
    feature_classes = arcpy.ListFeatureClasses()
    schema_classes = [fc for fc in feature_classes if f'.{schema}.' in fc]
    sorted_feature_classes = sorted(schema_classes)
    tables = arcpy.ListTables()
    table_classes = [fc for fc in tables if f'.{schema}.' in fc]
    sorted_table_classes = sorted(table_classes)
    #
    # arcpy.management.CreateFileGDB(output_gdb_path, gdb_name)
    # print(f"Geodatabase created: {output_gdb_path}/{gdb_name}")

    # Export all layers into the geodatabase at once
    arcpy.FeatureClassToGeodatabase_conversion(schema_classes, f"{gb.sde_root}/{schema}.gdb")

    #
    # for sde_fc in sorted_feature_classes:
    #     featurename = sde_fc.split(".")[-1]
    #     feature = f"{o}/{featurename} "
    #     # arcpy.CopyFeatures_management(sde_fc, feature)
    #     arcpy.conversion.ExportFeatures(sde_fc, feature)
    #
    # for sde_fc in sorted_table_classes:
    #     tablename = sde_fc.split(".")[-1]
    #     feature = f"{o}/{tablename} "
    #     # arcpy.CopyFeatures_management(sde_fc, feature)
    #     arcpy.conversion.ExportTable(sde_fc, feature)
    print(f"{output_gdb} created")
    return output_gdb

def create_gdb_zip(o):
    zipFile = f"{o}.zip"
    if os.path.exists(zipFile):
        print(f"removing {zipFile}")
        os.remove(zipFile)

    try:
        print(f"creating {zipFile}")
        shutil.make_archive(o, 'zip', root_dir=o, base_dir=".")
    except Exception as e:
        print(e)

    print(zipFile)

def upload_gdb_zip(o):
    # Upload the zipped GDB
    item_properties = {
        'title': 'National Structures - PA',
        'type': 'File Geodatabase',
        'itemType': "file",
        'tags': 'SDE, layers, tables, feature service',
        'description': 'Feature service with layers and tables from Coastal test.'
    }

    uploaded_item = gis.content.add(item_properties, f"{o}.zip")
    logger.info(f"uploaded {uploaded_item}")
    return uploaded_item

def main():
    global gis
    global project
    global outdir
    global logger
    global gb
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))
    logger = initialize_logger()
    args = process_args_load()
    config_json = None
    try:
        # Load the config
        with open(os.path.join(args["config_file"])) as json_data:
            config_json = json.load(json_data)
    except Exception as e:
        logger.error(f"Error Could not load  {gb.cfg_file}", e)
        sys.exit()
    gis = GIS("https://dev-portal.egis-usace.us/enterprise/home", "svc.publisher", 'svc.publisher2024!')

    gb = LoadGlobals(args, config_json)
    # load_product_source_details(logger, gb)
    # product_name = gb.product.collection_name
    schema = 'nsi'
    output_gdb_path = gb.sde_root
    gdb_file_name = f"{schema}.gdb"

    o = os.path.join(gb.sde_root, f"{gdb_file_name}")
    print(o)
    # output_gdb = create_gdb(schema, o)
    # create_gdb_zip( o)
    # item = upload_gdb_zip(o)
    # gpkg =  os.path.join(r"D:\data\nsi\nsi_2022_42.gpkg","nsi_2022_42.gpkg")
    item_props = ItemProperties(title="National Structure Inventory PA",
                                 item_type=ItemTypeEnum.GEOPACKAGE.value)
    item = gis.content.add(item_properties=item_props, data =gpkg)
    # item_props = ItemProperties(title="Coastal Data FDGB Hosted",
    #                             item_type=ItemTypeEnum.FILE_GEODATABASE.value)
    # item2 = gis.content.add(item_properties=item_props, data=rf"{o}.zip")
    # # search_results = gis.content.search('Coastal GDB',item_type="File Geodatabase")
    # item = search_results[0]
    #
    try:
        pubProps = {}
        pubProps["hasStaticData"] = 'true'
        pubProps["name"] = "National Structure Inventory PA"
        pubProps["title"] = "National Structure Inventory PA"
        pubProps["maxRecordCount"] = 2000
        pubProps["layerInfo"] = {"capabilities": "Query"}


        published_item = item.publish()
        print(published_item)
        print(f"Feature service published at: {published_item.url}")

        pubProps = {}
        pubProps["hasStaticData"] = 'true'
        pubProps["name"] = "Coastal Data"
        pubProps["title"] = "Coastal Data"
        pubProps["maxRecordCount"] = 2000
        pubProps["layerInfo"] = {"capabilities": "Query"}


        # published_item = item2.publish()
        # print(published_item)
        # print(f"Feature service published at: {published_item.url}")

    except Exception as e:
        print(e)


if __name__ == "__main__":
    main()
