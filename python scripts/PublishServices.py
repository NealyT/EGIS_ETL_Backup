'''
Publish a Service
'''
from arcgis.gis import GIS
import arcpy
import os

if __name__ == "__main__":


    project_path = arcpy.GetParameterAsText(0)
    group_layer_name = arcpy.GetParameterAsText(1)
    sde_connection = arcpy.GetParameterAsText(2)

    project = arcpy.mp.ArcGISProject(project_path)
    map = project.activeMap
    df = map.activeDataFrame
    # Path to your ArcGIS Pro project
    # project_path = r"D:\Users\lisa.f\Documents\ArcGIS\Projects\ProonWorkspaces\ProonWorkspaces.aprx"

    # Name of the group layer to be found


    groupLayer = arcpy.mapping.Layer(group_layer_name)
    arcpy.mapping.AddLayer(df, groupLayer, "BOTTOM")
    arcpy.env.workspace = sde_connection
    table_list = arcpy.ListTables("*", f"nld.*")
    for table in table_list:
        table_path = f"{sde_connection}/nld.{table}"
        table_layer = arcpy.mp.Layer(table_path)
        map.addLayerToGroup(groupLayer, table_layer)

        arcpy.management.MakeFeatureLayer(
            in_features=r"NLD_Layers\egdb.nld.cross_sections",
            out_layer="nld2.cross_sections_Layer",
            where_clause="",
            workspace=r"D:\Users\nealie.t\Documents\ArcGIS\Projects\EGIS_1\catalog-egis-dev.sde",
            field_info="objectid OBJECTID VISIBLE NONE;objectid_1 objectid_1 VISIBLE NONE;se_anno_cad_data se_anno_cad_data VISIBLE NONE;segment_id segment_id VISIBLE NONE;segment_name segment_name VISIBLE NONE;system_id system_id VISIBLE NONE;system_name system_name VISIBLE NONE;cross_sec_id cross_sec_id VISIBLE NONE;data_source data_source VISIBLE NONE;shape shape VISIBLE NONE;st_length(shape) st_length_shape_ VISIBLE NONE"
        )
    project.save()
    #
    # # Service properties
    # service_properties = {'name': 'New Feature Service', 'tags': 'demo, service'}
    #
    # # Output location for the layer file (.lyrx)
    # output_directory = r"D:\Users\lisa.f\Documents\ArcGIS\Projects\ProonWorkspaces"
    #
    # # Output location for the service definition draft file (.sddraft)
    # sddraft_file = os.path.join(output_directory, group_layer_name + ".sddraft")
    #
    # try:
    #     # Reference the ArcGIS Pro project
    #     aprx = arcpy.mp.ArcGISProject(project_path)
    #
    #     # Access the desired map in the project
    #     map_obj = aprx.listMaps()[0]  # Assuming the first map in the project
    #
    #     # Find the group layer by name
    #     group_layer = None
    #     for layer in map_obj.listLayers():
    #         if layer.isGroupLayer and layer.name == group_layer_name:
    #             group_layer = layer
    #             break
    #
    #     # Verify if a group layer with the specified name was found
    #     if group_layer:
    #         # Create a service definition draft
    #         arcpy.mp.CreateWebLayerSDDraft(map_obj, sddraft_file, service_name=service_properties['name'],
    #                                                 tags=service_properties['tags'], server_type='HOSTING_SERVER',
    #                                                 service_type='FEATURE_ACCESS', folder_name=None,
    #                                                 copy_data_to_server=True, summary=None, description=None,
    #                                                 credits=None, use_limitations=None)
    #
    #         # Stage the service definition
    #         sd_path = os.path.join(output_directory, service_properties['name'] + ".sd")
    #         arcpy.StageService_server(sddraft_file, sd_path)
    #
    #         # Publish the service definition
    #         arcpy.UploadServiceDefinition_server(sd_path, "EGIS Hosted Services")
    #
    #         print("Feature service published successfully")
    #
    #     else:
    #         print("Error: Group layer '{}' not found in the project.".format(group_layer_name))
    #
    # except Exception as e:
    #     print("Error:", e)