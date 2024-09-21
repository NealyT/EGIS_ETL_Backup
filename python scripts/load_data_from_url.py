
import arcpy
import requests
import json
import os
import datetime
import pandas as pd

class Globals:
    def __init__(self, sde_connection, stage_connection, load_path, dts):
        self.sde_connection = sde_connection
        self.stage_connection = stage_connection
        self.load_path = load_path
        self.dts = dts
class ProductConfig:
    def __init__(self, collection_id, collection_name, acronym):
        self.collection_id = collection_id
        self.collection_name = collection_name
        self.acronym = acronym

def load_urls_from_db(globals):

    try:

        sde_conn = arcpy.ArcSDESQLExecute(globals.stage_connection)
        where_clause = "where collection_code = 'CSPI'"
        # where_clause = ""
        # Build the SQL query with WHERE clause
        sql = f"SELECT url_address, collection_schema, collection_id, collection_name FROM bronze_meta.collection_sources_view {where_clause}"


        # rows = cursor.execute(sql).fetchall()
        rows = sde_conn.execute(sql)

            # Create a pandas DataFrame from the fetched data
        df = pd.DataFrame(rows, columns=["url_address", "collection_schema", "collection_id", "collection_name"])

        return df

    except Exception as e:
        print(f"Error: {e}")
        return pd.DataFrame()  # Return empty DataFrame in case of errors

def add_load_record(globals):
    try:
        sde_conn = arcpy.ArcSDESQLExecute(globals.stage_connection)
        #YYYY-MM-DD HH:MM:SS
        sql = f"INSERT INTO load_history (load_date,load_status) VALUES ('{globals.dts}','PRE_LOAD')"

        sde_conn.execute(sql)
        select_sql = f"SELECT MAX(load_id) FROM load_history"
        result = sde_conn.execute(select_sql)

        return result

    except Exception as e:
        print(f"Error: {e}")


def load_layer_to_sde2(load_id, globals, url, child_layer):
    name = child_layer["name"]
    type = child_layer['geometryType'].lower()
    url_id = child_layer["id"]
    child_url = f"{url}/{url_id}"
    standard_name = name.strip().replace(' ', '_').lower()
    target_table=f"{standard_name}"
    try:
        arcpy.FeatureClassToGeodatabase_conversion(
            child_layer,
            globals.stage_connection
        )
    except Exception as e:
        print(f"{e}")

def load_layer_to_sde(load_id, globals, url, child_layer):
    # postGIS(ogr_location, acronym, gfile, table_name, host, dbname, user_name, password)

    name = child_layer["name"]
    type = child_layer['geometryType'].lower()
    url_id = child_layer["id"]
    child_url = f"{url}/{url_id}"
    standard_name = name.strip().replace(' ', '_').lower()
    output_fc = f"{globals.sde_connection}/{standard_name}"
    initial_fc =  f"{globals.sde_connection}/{standard_name}"
    try:
        # First test if table exists in schema, if not, load it as a new sde table, with global ids.
        if not arcpy.Exists(output_fc):
            arcpy.conversion.ExportFeatures(child_url, output_fc)
            arcpy.AddGlobalIDs_management(output_fc)
        # If table has been loaded once, load to staging schema
        else:
            output_fc = f"{globals.sde_connection}/{standard_name}_{load_id}"
            if arcpy.Exists(output_fc):
                arcpy.management.Delete(output_fc)
            arcpy.conversion.ExportFeatures(child_url, output_fc)
            arcpy.management.AddJoin(output_fc, "objectid", initial_fc, "objectid")
            # Calculate the field
            source_field = "globalid"
            expression = f'!$feature["{standard_name}.globalid"]'
            # expression = f"!{initial_fc}.{source_field}!"
            arcpy.management.CalculateField(output_fc, source_field, expression, "ARCADE")
            arcpy.management.RemoveJoin(output_fc, initial_fc)

        arcpy.management.AddField(output_fc, "load_id", "INTEGER")
        arcpy.management.CalculateField(output_fc, "load_id", f"{load_id}")

        desc = arcpy.da.Describe(output_fc)
        print(f"{name},{standard_name},{type},{child_url},{output_fc}")

    except Exception as e:
        print(e)

def load_table_to_sde(load_id, globals, url, child_layer):
    # postGIS(ogr_location, acronym, gfile, table_name, host, dbname, user_name, password)

    name = child_layer["name"]
    url_id = child_layer["id"]
    child_url = f"{url}/{url_id}"
    standard_name = name.strip().replace(' ', '_').lower()
    output_fc = f"{globals.sde_connection}/{standard_name}"

    try:
        # First test if table exists in schema, if not, load it as a new sde table, with global ids.
        if not arcpy.Exists(output_fc):
            arcpy.conversion.ExportTable(child_url, output_fc)
            arcpy.AddGlobalIDs_management(output_fc)
        # If table has been loaded once, load to staging schema
        else:
            output_fc = f"{globals.sde_connection}/{standard_name}_{load_id}"
            if arcpy.Exists(output_fc):
                arcpy.management.Delete(output_fc)
            arcpy.conversion.ExportTable(child_url, output_fc)
        arcpy.management.AddField(output_fc, "load_id", "INTEGER")
        arcpy.management.CalculateField(output_fc, "load_id", f"{load_id}")
        desc = arcpy.da.Describe(output_fc)
        print(f"{name},{standard_name},{type},{child_url},{output_fc}")

    except Exception as e:
        print(e)

def load_url(globals, collection, feature_server_url):


    # Connect to the feature server
    arcpy.env.workspace = feature_server_url

    data = get_server_response(globals,collection, feature_server_url, globals.dts)


    #
    # for layer in layer_list:
    #     print(layer)
    #     childData = arcpy.da.Describe(layer)
    #     print(childData)
    #     # Export layer to the file geodatabase
    #     #arcpy.CopyFeatures_management(layer, os.path.join(output_gdb, layer))
    #
    # for table in table_list:
    #     print(table)
    #     # Export table to the file geodatabase
    #     #arcpy.CopyRows_management(table, os.path.join(output_gdb, table))
def save_response_json(path, file_name, response_json):
    file_path = os.path.join(path, f"{file_name}.json")
    if not os.path.exists(path):
        os.makedirs(path)

    with open(file_path, 'w') as jsonfile:
        json.dump(response_json, jsonfile, indent=4)


    return file_path

def get_server_response(globals, productConfig: ProductConfig, url, load_id):
    new_row = None
    try:
        response = requests.get(url, params={"f": "json"})
        urlJson = response.json()
        json_file_name =productConfig.acronym+"_"+ productConfig.collection_name.strip().replace(" ", "_")
        simple_dts = globals.dts.replace(' ', '_').replace(':','').replace('-','')
        collection_file_path = save_response_json(f"{globals.load_path}\{simple_dts}", json_file_name, urlJson)

        layer_count = len(urlJson["layers"]) if "layers" in urlJson else 0
        table_count = len(urlJson["tables"]) if "tables" in urlJson else 0

        serviceItemId = urlJson['serviceItemId'] if 'serviceItemId' in urlJson else ''
        serviceDescription = urlJson['serviceDescription'] if 'serviceDescription' in urlJson else ''
        description = urlJson['description'] if 'description' in urlJson else ''
        srid = ''
        if 'spatialReference' in urlJson:
            if 'wkid' in urlJson['spatialReference']:
                srid = urlJson['spatialReference']['wkid']
        new_row = {'Collection_Code': "f{productConfig.acronym}",
                   'Collection_Id': "f{productConfig,collection_id}",
                   'Collection_Name': "f{productConfig.collection_name}",
                   'load_datetimestamp':  globals.dts,
                   'wkid': srid,
                   'layer_count': layer_count,
                   'table_count': table_count,
                   'load_status': 'preloaded',
                   'source_file_path': collection_file_path,
                   'serviceItemId': serviceItemId,
                   'url': url,
                   'serviceDescription': f'{serviceDescription}',
                   'description': f'{description}'}

        if "layers" in urlJson:
            for child in urlJson["layers"]:
                # new_layer = load_layer_to_sde(load_id,globals, url, child)
                load_layer_to_sde2(load_id, globals, url, child)
        if "tables" in urlJson:
            for child in urlJson["tables"]:
                # new_table = load_table_to_sde(load_id, globals, url, child)
                print('bypass for now')
    except Exception as e:
        print(e)
    return new_row


def main():
    base_location = arcpy.GetParameterAsText(0)
    staging_schema = arcpy.GetParameterAsText(1)
    sde_root_connection = arcpy.GetParameterAsText(2)
    # D:\\Users\nealie.t\Documents\ArcGIS\Projects\EGIS_1\catalog-egis-dev.sde
    acronym = 'CSPI'
    sde_connection = f"{sde_root_connection}\{acronym}-egis-dev.sde"
    stage_connection = f"{sde_root_connection}\{staging_schema}-egis-dev.sde"
    now = datetime.datetime.now()
    print(now)
    # Convert to string in a specific format (YYYY-MM-DD HH:MM:SS)
    formatted_dts = now.strftime("%Y-%m-%d %H:%M:%S")

    globals = Globals(sde_connection, stage_connection, base_location, formatted_dts)

    df = load_urls_from_db(globals)

    load_id = add_load_record(globals)

    for index, row in df.iterrows():
        acronym = row['collection_schema']
        collection_name = row['collection_name']
        collection_id = row['collection_id']
        url = row['url_address'].strip()
        print(url)
        collection = ProductConfig(collection_id, collection_name, acronym)
        arcpy.env.workspace = url
        data = get_server_response(globals, collection, url, load_id)

    # Replace with your feature server URL
    # feature_server_url = r"https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/CSPI_DataCall_AllData/FeatureServer"
    # load_url(globals, feature_server_url)

if __name__ == "__main__":
    main()