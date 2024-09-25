
import os
import datetime
import pandas as pd
import sys
import arcpy
import re
import etl_scripts.bronze.utils as egis_utils

# Include, environment variable, CRYPTOGRAPHY_OPENSSL_NO_LEGACY = true
class Globals:
    def __init__(self, args, configs,logger):
        now = datetime.datetime.now()
        formatted_dts = now
        sde_root = configs["sde_root"]
        db_user = configs["db_user"]
        db_env = configs["db_env"]

        self.sde_connection = f"{sde_root}\{db_user}-{db_env}.sde"
        self.dts = formatted_dts
        self.sde_root = sde_root
        self.db_user = configs["db_user"]
        self.db_database = configs["db_database"]
        self.db_env = configs["db_env"]
        self.db_instance = configs["db_instance"]
        self.catalog_role = configs["catalog_role"]
        self.logger = logger
        self.aws_region = args["aws_region"]

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
    work_items = egis_utils.get_data(gb, 'etl_loader.etl_control_view')

    for index, row in work_items.iterrows():
        schema = row['schema_prefix']
        collection_name = row['name']
        data_product_id = row['data_product_id']
        source_id = row['source_id']
        path = row['path']
        gb.logger.info(f"{schema} {collection_name} {data_product_id} {source_id} {path}")
    gb.logger.info("Completed Load Process")

if __name__ == "__main__":
    main()