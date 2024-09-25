from arcgis.gis import GIS
import arcpy
import os
import sys
import datetime
import etl_scripts.bronze.utils as egis_utils
import xml.dom.minidom as DOM
import pandas as pd

class Globals:
    def __init__(self, dts, args):
        formatted_dts = dts
        sde_root = args["sde_root"]
        self.catalog_user = None if "catalog_user" not in args else args["catalog_user"]
        self.sde_connection = f"{sde_root}\etl_loader-dev.sde"
        self.product_path = args["sde_root"]
        self.dts = formatted_dts
        self.product = egis_utils.DataProduct(args["data_product_id"], args["source_id"])
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

def load_product_source_details(logging, gb):
    try:
        logging.info("Retrieving data product details from RDBMS")
        sde_conn = arcpy.ArcSDESQLExecute(gb.sde_connection)
        where_clause = f"where data_product_id = {gb.product.product_id} and source_id = {gb.product.source_id}"
        # Build the SQL query with WHERE clause
        sql = f'''
                SELECT path, schema_prefix as collection_schema, name as collection_name, 
                    coalesce(properties_json->>'tags','') tags,
                	properties_json->>'copyrightText' copyright_text,
                    properties_json ->>'description' description,
                    properties_json ->>'serviceDescription' serviceDescription	
                FROM etl_loader.etl_control_view {where_clause}'''

        logging.info(f"SQL to get data for service definition: {sql}")
        rows = sde_conn.execute(sql)

        df = pd.DataFrame(rows, columns=["path", "collection_schema", "collection_name","tags",
                                         "copyright_text","description","service_description"])
        first_row = df.iloc[0]

        gb.product.collection_name = first_row['collection_name']
        gb.product.schema = first_row['collection_schema'].lower()
        gb.load_schema =gb.product.schema
        gb.product.source_path = first_row['path']
        gb.description = first_row['description']
        gb.service_description = first_row['service_description']
        gb.copyright_text = first_row['copyright_text']
        gb.tags = first_row['tags']

        logging.info(f"{gb.product.schema} : {gb.product.collection_name} : {gb.product.source_path}")

    except Exception as e:
        logging.error("Error Retrieving data product details from RDBMS", e)

def configure_featureserver_capabilities(sddraftPath, capabilities):
    """Function to configure FeatureServer properties"""
    # Read the .sddraft file
    doc = DOM.parse(sddraftPath)

    # Find all elements named TypeName
    # This is where the additional layers and capabilities are defined
    typeNames = doc.getElementsByTagName('TypeName')
    for typeName in typeNames:
        # Get the TypeName to enable
        if typeName.firstChild.data == "FeatureServer":
            extension = typeName.parentNode
            for extElement in extension.childNodes:
                if extElement.tagName == 'Info':
                    for propSet in extElement.childNodes:
                        for prop in propSet.childNodes:
                            for prop1 in prop.childNodes:
                                if prop1.tagName == "Key":
                                    if prop1.firstChild.data == 'WebCapabilities':
                                        if prop1.nextSibling.hasChildNodes():
                                            prop1.nextSibling.firstChild.data = capabilities
                                        else:
                                            txt = doc.createTextNode(capabilities)
                                            prop1.nextSibling.appendChild(txt)
    # Write to the .sddraft file
    f = open(sddraftPath, 'w')
    doc.writexml(f)
    f.close()


def configure_mapserver_capabilities(sddraftPath, capabilities):
    """Function to configure MapServer properties"""
    # Read the .sddraft file
    doc = DOM.parse(sddraftPath)

    # Find all elements named TypeName
    # This is where the additional layers and capabilities are defined
    typeNames = doc.getElementsByTagName('TypeName')
    for typeName in typeNames:
        # Get the TypeName to enable
        if typeName.firstChild.data == "MapServer":
            extension = typeName.parentNode
            for extElement in extension.childNodes:
                if extElement.tagName == 'Definition':
                    for propArray in extElement.childNodes:
                        if propArray.tagName == 'Info':
                            for propSet in propArray.childNodes:
                                for prop in propSet.childNodes:
                                    for prop1 in prop.childNodes:
                                        if prop1.tagName == "Key":
                                            if prop1.firstChild.data == 'WebCapabilities':
                                                if prop1.nextSibling.hasChildNodes():
                                                    prop1.nextSibling.firstChild.data = capabilities
                                                else:
                                                    txt = doc.createTextNode(capabilities)
                                                    prop1.nextSibling.appendChild(txt)
    # Write to the .sddraft file
    f = open(sddraftPath, 'w')
    doc.writexml(f)
    f.close()


def add_data(current_map):
    sde_connection = f"{gb.sde_root}\server_connection.sde"
    schema = gb.product.schema
    arcpy.env.workspace = sde_connection
    feature_classes = arcpy.ListFeatureClasses()
    schema_classes = [fc for fc in feature_classes if f'.{schema}.' in fc]
    sorted_feature_classes = schema_classes
    tables = arcpy.ListTables()
    table_classes = [fc for fc in tables if f'.{schema}.' in fc]

    for fc in sorted_feature_classes:
        layer_name = fc.split(".")[-1]

        layer = current_map.addDataFromPath(f"{sde_connection}\\{fc}")
        if layer:
            # Modify layer properties if needed
            layer.name = layer_name  # Change the layer name

    for fc in table_classes:
        layer_name = fc.split(".")[-1]

        layer = current_map.addDataFromPath(f"{sde_connection}\\{fc}")
        if layer:
            # Modify layer properties if needed
            layer.name = layer_name  # Change the layer name
    project.save()

def set_allow_exports(docs):
    allow_export = docs.getElementsByTagName("AllowExportData")

    if len(allow_export) == 0:
        # If the AllowExportData tag doesn't exist, create it and append to the appropriate place
        properties = docs.getElementsByTagName("ConfigurationProperties")[0]

        new_tag = docs.createElement("AllowExportData")
        new_tag.appendChild(docs.createTextNode("true"))  # Set to 'true' or 'false'

        # Append the new AllowExportData tag to ConfigurationProperties
        properties.appendChild(new_tag)
        # print("AllowExportData tag has been created and added.")
    else:
        # If it exists, update its value
        allow_export[0].firstChild.data = "true"  # Or "false"

def create_map(product_name):
    map_name = f"{product_name}"
    map_same = None
    for m in project.listMaps():
        if m.name == map_name:
            map_same = m
            break

    if map_same:
        for lyr in map_same.listLayers():
            map_same.removeLayer(lyr)
        for tbl in map_same.listTables():
            map_same.removeTable(tbl)
        project.save()
    else:
        map_same = project.createMap(map_name, "MAP")
        for lyr in map_same.listLayers():
            map_same.removeLayer(lyr)  # Remove any base map layers
        project.save()
    add_data(map_same)
    logging.info(f"Map {map_name} has {len(map_same.listLayers())} layers and {len(map_same.listTables())} tables")
    return map_same


def create_services_from_datastore(schema, outdir, map, gis):
    # Replace with the datastore name or ID
    datastore_name = "ASR_RO_DB_CONNECT"
    items = gis.content.search("ASR_RO_DB_CONNECT")
    # print(items)
    federated_server_url = "https://dev-portal.egis-usace.us/server/manager/"

    # Connect to ArcGIS Server
    gis_server = gis.server.Server(federated_server_url)

    # List the layers in the datastore
    # Get the datastore
    datastore = gis_server.datastores["ASR_RO_DB_CONNECT"]

    # List the layers or tables in the datastore
    layers_or_tables = datastore.list_datasets()

    # Print the layer or table names
    for item in layers_or_tables:
        print(item.name)

    # Specify the layers you want to publish (replace with actual layer names)
    layers_to_publish = ["layer1", "layer2", "layer3"]

    # Publish the specified layers
    published_layers = datastore.publish_datasets(datasets=layers_to_publish)

    # Print the published layers
    print(published_layers)


def create_web_layer(schema, outdir, map, copy=False):
    service_name = map.name.replace(" ", "_")
    sddraft_filename = service_name + "C.sddraft"
    sddraft_output_filename = os.path.join(outdir, sddraft_filename)
    if os.path.exists(sddraft_output_filename):
        os.remove(sddraft_output_filename)
    sd_filename = service_name + "C.sd"
    sd_output_filename = os.path.join(outdir, sd_filename)
    if os.path.exists(sd_output_filename):
        os.remove(sd_output_filename)
    tags = f"ASR, EGIS, USACE, {schema}, {map.name.replace('Data', '')}"
    arcpy.mp.CreateWebLayerSDDraft(map, sddraft_output_filename, service_name=f"C {map.name}",
                                   tags=tags, server_type='HOSTING_SERVER',
                                   service_type='FEATURE_ACCESS', folder_name=None,
                                   copy_data_to_server=copy, summary=None, description=None,
                                   credits=None, use_limitations=None)

    arcpy.StageService_server(sddraft_output_filename, sd_output_filename)

    # Publish the service definition
    arcpy.UploadServiceDefinition_server(sd_output_filename, "My Hosted Services")

    logging.info("Feature service published successfully")

def toggle_types(docs, types):
    # Find all elements named TypeName
    # This is where the extensions are defined
    descriptions = docs.getElementsByTagName('Type')
    for desc in descriptions:
        if desc.parentNode.tagName == 'SVCManifest':
            if desc.hasChildNodes():
                desc.firstChild.data = 'esriServiceDefinitionType_Replacement'
    # ["FeatureServer", "WMSServer", "WFSServer", "OGCFeatureServer"]:
    typeNames = docs.getElementsByTagName('TypeName')
    for typeName in typeNames:
        # Get the TypeName to enable
        # if typeName.firstChild.data == "FeatureServer":
        # print(typeName.firstChild.data)
        if typeName.firstChild.data in types:
            extension = typeName.parentNode
            for extElement in extension.childNodes:
                # Include a feature layer
                if extElement.tagName == 'Enabled':
                    extElement.firstChild.data = 'true'

def toggle_feature_capabilities(docs, types):
    typeNames = docs.getElementsByTagName('TypeName')
    for typeName in typeNames:
        # Get the TypeName to enable
        if typeName.firstChild.data == "FeatureServer":
            extension = typeName.parentNode
            for extElement in extension.childNodes:
                # print(extElement.tagName)
                if extElement.tagName == 'Info':
                    for propSet in extElement.childNodes:
                        for prop in propSet.childNodes:
                            for prop1 in prop.childNodes:
                                if prop1.tagName == "Key":
                                    # print(prop1.firstChild.data)
                                    if prop1.firstChild.data == 'WebCapabilities':
                                        # Defaults are Query,Create,Update,Delete,Extract,Editing
                                        prop1.nextSibling.firstChild.data = types

def set_property(docs,propertyName, propertyValue):
    properties = docs.getElementsByTagName('PropertySetProperty')
    for prop in properties:
        key = prop.getElementsByTagName('Key')[0].firstChild.data
        value = prop.getElementsByTagName('Value')[0]

        if key == propertyName:
            value.firstChild.data = f'{propertyValue}'  # Set the desired minimum instances

def set_sharing_props(gis, docs, org=False, all=False, groups="Authoritative Content"):

    groupItem = gis.groups.search(f"title:{groups}")
    GroupId = None
    if len(groupItem) > 0:
        GroupId = groupItem[0].id;

    key_list = docs.getElementsByTagName('Key')
    value_list = docs.getElementsByTagName('Value')

    # Change following to "true" to share
    SharetoOrganization = "false" if not org else "true"
    SharetoEveryone = "false" if not all else "true" # BUG FIX 3.2 https://support.esri.com/en-us/bug/staging-a-web-feature-service-wfs-using-python-fails-an-bug-000159853
    SharetoGroup = "false" if not GroupId else "true"

    # Each key has a corresponding value. In all the cases, value of key_list[i] is value_list[i].
    for i in range(key_list.length):
        if key_list[i].firstChild.nodeValue == "PackageUnderMyOrg":
            value_list[i].firstChild.nodeValue = SharetoOrganization
        if key_list[i].firstChild.nodeValue == "PackageIsPublic":
            value_list[i].firstChild.nodeValue = SharetoEveryone
        if key_list[i].firstChild.nodeValue == "PackageShareGroups":
            value_list[i].firstChild.nodeValue = SharetoGroup
        if SharetoGroup == "true" and key_list[i].firstChild.nodeValue == "PackageGroupIDs":
            if value_list[i].hasChildNodes():
                value_list[i].firstChild.nodeValue = GroupId
            else:
                # Create a new child node and set its value
                new_node = docs.createTextNode(GroupId)
                value_list[i].appendChild(new_node)
def get_web_layer_sharing_draft(gis, schema, outdir, map):
    map_name = map.name
    service_name = map_name.replace(" ", "_")
    sddraft_filename = service_name + ".sddraft"
    sddraft_output_filename = os.path.join(outdir, sddraft_filename)
    sd_filename = service_name + ".sd"
    sd_output_filename = os.path.join(outdir, sd_filename)
    # propss = json.loads(gb.product.properties_json)

    # Create FeatureSharingDraft and set metadata, portal folder, export data properties, and CIM symbols
    federated_server_url = "https://dev-portal.egis-usace.us/server"

    sddraft = map.getWebLayerSharingDraft("FEDERATED_SERVER", "MAP_IMAGE", f"{map_name}")
    sddraft.federatedServerUrl = federated_server_url
    sddraft.copyDataToServer = False
    sddraft.credits = gb.copyright_text
    sddraft.description = ""
    sddraft.summary = gb.service_description


    sddraft.tags = f"ASR, EGIS, USACE, {schema}"
    if gb.tags != '':
        sddraft.tags += f',{gb.tags}'
    sddraft.useLimitations = "These are use limitations"
    sddraft.portalFolder = f"{schema}"
    sddraft.serverFolder = f"{schema}"
    sddraft.useCIMSymbols = True
    sddraft.overwriteExistingService = True


    logging.info(f"Exporting service definition to {sddraft_output_filename}")
    # Create Service Definition Draft file
    sddraft.exportToSDDraft(sddraft_output_filename)
    configure_mapserver_capabilities(sddraft_output_filename, "Map,Query,Data")

    # Read the .sddraft file
    docs = DOM.parse(sddraft_output_filename)
    toggle_types(docs, ["FeatureServer"])
    toggle_feature_capabilities(docs,"Query,Extract")

    set_sharing_props(gis,docs, org=False, all=False, groups="Authoritative Content")
    set_property(docs,"MinInstances", 2)

    # Write to new .sddraft file
    sddraft_mod_xml = service_name + '_mod_xml' + '.sddraft'
    sddraft_mod_xml_file = os.path.join(outdir, sddraft_mod_xml)
    f = open(sddraft_mod_xml_file, 'w')
    docs.writexml(f)
    f.close()

    # Stage Service
    logging.info(f"Starting Staging of {sddraft_mod_xml_file}")
    if os.path.exists(sd_output_filename):
        try:
            os.remove(sd_output_filename)
        except Exception as e:
            logging.error(f"Could not delete {sd_output_filename}", e)

    staged = False
    try:
        arcpy.server.StageService(sddraft_mod_xml_file, sd_output_filename)
        staged = True
    except Exception as e:
        print(e)

    if staged:
        logging.info(f"Starting Uploading Service Definition: {sd_output_filename}")

        try:
            result = arcpy.server.UploadServiceDefinition(in_sd_file=sd_output_filename,
                                                          in_server=federated_server_url,
                                                          # in_override="OVERRIDE_DEFINITION",
                                                          # in_public="PRIVATE",
                                                          # in_organization="NO_SHARE_ORGANIZATION",
                                                          # in_groups="Authoritative Content"
                                                          )


            item_title = f"{map_name}"
            items = gis.content.search(f"title:{item_title}")

            description = f'''
            The data provided by this service was harvested from the following sources:
           <ul>
            <li><a href="{gb.product.source_path}" target="blank">{gb.product.collection_name}</a></li>
           </ul> 
            {gb.description}
             
            '''
            for feature_service_item in items:
                try:

                    fp = rf"D:\projects\eGIS-Web-App\public\static\images\card\usace-{schema.lower()}.jpg"
                    feature_service_item.update_thumbnail(file_path=fp)
                    # feature_service_item.content_status = "authoritative"
                    feature_service_item.update(item_properties={'description': f'{description}'})
                    feature_service_item.update()

                except Exception as e:
                    logging.error("Problem updating {feature_service_item.title} properties", e)

            logging.info(f"Successfully Published {item_title}")

        except Exception as e:
            logging.error("Problem with UploadServiceDefinition {sd_output_filename}", e)


def init_globals() -> Globals:
    logging.info("Started Load Process, Initializing")
    now = datetime.datetime.now()
    args = egis_utils.process_args_publish()
    gb = Globals(now, args)
    logging.info(f"Loading Product data for {gb.product.product_id} Source {gb.product.source_id}")
    return gb


def main():
    global gis
    global project
    global outdir
    global logging
    global gb
    global gis
    #
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))
    now = datetime.datetime.now()
    formatted_date = now.strftime('%Y%m%d%H%M%S')
    args = process_args_publish()
    log_dir = args["log_dir"]
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, f"{formatted_date}_load.log")
    #
    logging = initialize_logger(log_file=log_file, debug=True)
    gb = init_globals()
    load_product_source_details(logging, gb)
    product_name = gb.product.collection_name

    gis = GIS("https://dev-portal.egis-usace.us/enterprise", "svc.publisher", "svc.publisher2024!")
    #
    project_path = r"D:\Users\nealie.t\Documents\ArcGIS\Projects\EGIS_Server_Project\EGIS_Server_Project.aprx"
    project = arcpy.mp.ArcGISProject(project_path)
    outdir = os.path.dirname(project_path)
    try:
        map = create_map(product_name)
        get_web_layer_sharing_draft(gis, gb.product.schema, outdir, map)
    except Exception as e:
        logging.error("Exception occurred", e)


if __name__ == "__main__":
    main()
