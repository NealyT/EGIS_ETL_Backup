
import arcpy
import arcgis
from arcgis.gis import GIS
import os
import shutil
import zipfile

gis = GIS("https://dev-portal.egis-usace.us/enterprise/home", "svc.publisher", 'svc.publisher2024!')
datastore =  gis.datastore

ds_items = gis.content.search("ASR_ro_Connection", item_type="Data Store")
for ds_item in ds_items:
    print(f"{ds_item.title:33}{ds_item.id}{' '*2}{ds_item.get_data()['type']}")
dstore = ds_items[0]
portal_folderid = [f["id"] for f in gis.users.me.folders][0]
# server_list = gis.admin.federation.servers["servers"]
host_id = 'https://dev-portal.egis-usace.us/server'

service_template = {"serviceName": None,
                    "type": "MapServer",
                    "capabilities":"Map,Query",
                    "extensions": [{"typeName": "FeatureServer",
                                    "capabilities":"Query,Create,Update,Delete",
                                    "enabled": "true",
                                    "properties": {"maxRecordCount": 5000}}]}

bulk_publish_job = datastore.publish_layers(item = dstore,
                                             srv_config = service_template,
                                             server_id = host_id,
                                             folder = portal_folderid,
                                             server_folder=portal_folderid)
bulk_publish_job
# project_pkg = gis.content.get("5c1e147ada9a47abb96a073c04f3e582")
project_pkg = gis.content.get("8273b4c5a64540619029d3c569c70645")
# item_id = project.id
# url = project.url
# json = project.json
project_package = project_pkg.download()

# print("Project package downloaded to:", project_package)
# dproject = arcpy.mp.ArcGISProject(r"D:\Users\nealie.t\AppData\Local\Temp\1\EGIS_Server_Project.ppkx")
output_directory = r"D:\Users\nealie.t\Documents\ArcGIS\Projects2"

# Unpack the project package
print(project_package)
# with zipfile.ZipFile(project_package, 'r') as zip_ref:
#     zip_ref.extractall(output_directory)
# shutil.unpack_archive(project_package, output_directory)
unpacked_project = os.path.join(output_directory, "EGIS_Server_Project.aprx")

# Open the unpacked project in ArcGIS Pro
aprx = arcpy.mp.ArcGISProject(unpacked_project)
maps = aprx.maps
if len(maps) == 0:
    print("The project does not contain any maps.")
else:
    print("The project contains", len(maps), "maps.")

for map in aprx.maps:
    print(map)
# Do something with the map

arcpy.management.CreateDatabaseConnection(
    out_folder_path=r".",
    out_name="server_connection",
    database_platform="POSTGRESQL",
    instance="degisegdb-replica.cvvlw7qn7lxg.us-gov-west-1.rds.amazonaws.com",
    account_authentication="DATABASE_AUTH",
    username="bronze_catalog",
    password='bronze_catalog',
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
print("did this work?")