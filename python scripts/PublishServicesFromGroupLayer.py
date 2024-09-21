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


    # Service properties
    service_properties = {'name': 'New Feature Service', 'tags': 'demo, service'}

    # Output location for the layer file (.lyrx)
    output_directory = r"D:\Users\lisa.f\Documents\ArcGIS\Projects\ProonWorkspaces"

    # Output location for the service definition draft file (.sddraft)
    sddraft_file = os.path.join(output_directory, group_layer_name + ".sddraft")

    try:
        # Reference the ArcGIS Pro project
        aprx = arcpy.mp.ArcGISProject(project_path)

        # Access the desired map in the project
        map_obj = aprx.listMaps()[1]  # Assuming the first map in the project

        # Find the group layer by name
        group_layer = None
        for layer in map_obj.listLayers():
            if layer.isGroupLayer and layer.name == group_layer_name:
                group_layer = layer
                break

        # Verify if a group layer with the specified name was found
        if group_layer:
            # Create a service definition draft
            arcpy.mp.CreateWebLayerSDDraft(map_obj, sddraft_file, service_name=service_properties['name'],
                                                    tags=service_properties['tags'], server_type='HOSTING_SERVER',
                                                    service_type='FEATURE_ACCESS', folder_name=None,
                                                    copy_data_to_server=True, summary=None, description=None,
                                                    credits=None, use_limitations=None)

            # Stage the service definition
            sd_path = os.path.join(output_directory, service_properties['name'] + ".sd")
            arcpy.StageService_server(sddraft_file, sd_path)

            # Publish the service definition
            arcpy.UploadServiceDefinition_server(sd_path, "EGIS Hosted Services")

            print("Feature service published successfully")

        else:
            print("Error: Group layer '{}' not found in the project.".format(group_layer_name))

    except Exception as e:
        print("Error:", e)