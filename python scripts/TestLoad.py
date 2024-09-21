import arcpy
import arcgis
from arcgis.features import FeatureLayerCollection, FeatureLayer

import pandas as pd
import requests
import json

if __name__ == "__main__":
    # Set data
    # in_data = "https://geospatial.sec.usace.army.mil/server/rest/services/NLD2_PUBLIC/FeatureServer/14"
    in_data = "https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services/usace_cw_districts/FeatureServer/0"
    import arcpy

    # Define the paths
    geojson_path = r"D:\\data\DIS\dis_placements.geojson"
    sde_connection = r"D:\\Users\nealie.t\Documents\ArcGIS\Projects\EGIS_1\catalog-nld-egis-dev.sde"
    output_feature_class = "dis_placements"
    child_layer = arcpy.FeatureSet()
    child_layer.load(in_data)
    if hasattr(child_layer, "GeoJSON"):
        # Convert GeoJSON to a feature class
        temp_fc = "in_memory/temp_fc"
        arcpy.JSONToFeatures_conversion(geojson_path, temp_fc, 'POINT')
        feature_count2 = arcpy.GetCount_management(temp_fc)
        desc = arcpy.da.Describe(temp_fc)

        # Copy the feature class to SDE
        arcpy.FeatureClassToFeatureClass_conversion(temp_fc, sde_connection, output_feature_class)

        print(f"GeoJSON data successfully loaded into {output_feature_class}")