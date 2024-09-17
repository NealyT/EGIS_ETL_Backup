import logging
import argparse
import arcpy

class DataProduct:
    def __init__(self, product_id, source_id, collection_name=None, schema=None, source_path=None):
        self.product_id = product_id
        self.source_id = source_id
        self.collection_id = product_id
        self.collection_name = collection_name
        self.schema = schema
        self.source_path = source_path

class Globals:
    def __init__(self, dts, args):
        formatted_dts = dts
        sde_root = args["sde_root"]
        #result = "Even" if x % 2 == 0 else "Odd"
        self.catalog_user = None if "catalog_user" not in args else args["catalog_user"]
        self.sde_connection = f"{sde_root}\etl_loader-dev.sde"
        self.product_path = args["sde_root"]
        self.dts = formatted_dts
        self.product = DataProduct(args["data_product_id"], args["source_id"])
        self.sde_root = sde_root
        self.user_connection = None
        self.load_schema = None
        self.etl_record = None
        self.entities = None
        self.mapped_columns = None
        self.description = None
        self.service_description = None
        self.copyright_text = None
        self.tags = None
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
    parsed_args = parser.parse_args()
    args = vars(parsed_args)
    return args
