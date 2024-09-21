import arcpy
import os
from arcgis.features import FeatureLayerCollection, FeatureLayer
import pandas as pd
def arcpy_dtype_mapping(pd_dtype):
    """Maps Pandas data types to ArcPy field types"""
    if pd_dtype == 'int64':
        return 'LONG'
    elif pd_dtype == 'float64':
        return 'DOUBLE'
    elif pd_dtype == 'datetime64[ns]':
        return 'DATE'  # Or 'DATETIME' based on your needs
    elif pd_dtype == 'object':
        return 'TEXT'  # Adjust based on actual data content
    else:
        return 'TEXT'  # Default to text for unknown types

def create_schema_user(sde_connection, acronym):
    # Query to check if the user exists

    username  = 'catalog_' + acronym.replace("'", "''")  # Escape single quotes

    # Use field delimiters for the SQL expression
    field_name = 'sde_user'
    sql_expression = f"{field_name} = '{username}'"

    username = f'catalog_{acronym}'
    query = f"SELECT 1 FROM pg_user WHERE {sql_expression}'"
    user_exists = False
    try:
        fc = r'C:\path\to\your\geodatabase.gdb\your_feature_class'
        with arcpy.da.SearchCursor(sde_connection, [field_name], query) as cursor:
            user_exists = any(cursor)
            if user_exists:
                print(f"User '{username}' exists in the database.")
            else:
                print(f"User '{username}' does not exist in the database.")
    except Exception as e:
        print(f"An error occurred: {e}")

    if not user_exists:
        # Create Database User (need to check if it exists first)...
        arcpy.management.CreateDatabaseUser(
            input_database=sde_connection,
            user_authentication_type="DATABASE_USER",
            user_name=f"catalog_{acronym}",
            user_password=f"catalog_{acronym}",
            role="catalog",
            tablespace_name=f"catalog_{acronym}"
        )

def create_schema_connection_file(sde_connection, acronym, staged_env = 'dev'):
    directory_path = os.path.dirname(sde_connection)
    print(directory_path)
    out_name = f"catalog-{acronym}-egis-{staged_env}"
    connection_file = os.path.join(directory_path, out_name)
    sde_connect_file = f'{connection_file}.sde'
    if not os.path.exists(sde_connect_file):

        sde_connect_file = arcpy.management.CreateDatabaseConnection(
            out_folder_path=directory_path,
            out_name=out_name,
            database_platform="POSTGRESQL",
            instance="degisegdb.cvvlw7qn7lxg.us-gov-west-1.rds.amazonaws.com",
            account_authentication="DATABASE_AUTH",
            username=f'catalog_{acronym}',
            password=f'catalog_{acronym}',
            save_user_pass="SAVE_USERNAME",
            database="egdb",
            schema="",
            version_type="TRANSACTIONAL",
            version="sde.DEFAULT",
            date=None,
            auth_type="",
            project_id="",
            default_dataset="",
            refresh_token='',
            key_file=None,
            role="",
            warehouse="",
            advanced_options=""
        )
    return sde_connect_file

def load_layer(connection, lyr):
    print(f"{lyr.properties.name} {lyr.properties.extent.spatialReference.wkid} {lyr.estimates['count']}")

    name = lyr.properties.name.replace(' ', '_').lower()
    schema = 'test'
    out_feature_class = connection + "\\" + name
    features = []
    query = lyr.query(where='1=1', out_fields='*', return_geometry=True)

    sdf = query.sdf
    # features.extend(query.features)
    # while query.exceededTransferLimit:
    #     query = layer.query(where='1=1', out_fields='*', return_geometry=True, result_offset=len(features))
    #     features.extend(query.features)
    #
    # feature_count = len(features)
    # # Convert to DataFrame
    # print(f"{name} has{feature_count} features")
    # sdf = pd.DataFrame.spatial.from_featureset(features)
    sdf.spatial.to_featureclass(location=out_feature_class, sanitize_columns=True, overwrite=True)

if __name__ == "__main__":

    sde_connection = arcpy.GetParameterAsText(0)
    feature_service = arcpy.GetParameterAsText(1)
    acronym = 'nld'
    create_schema_user(sde_connection, acronym)
    new_connection = create_schema_connection_file(sde_connection, acronym)
    layer_collection = FeatureLayerCollection(feature_service)

    first_layer = layer_collection.layers[0]
    for lyr in layer_collection.layers:
       load_layer(new_connection,lyr)