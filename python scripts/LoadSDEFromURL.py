import arcpy
from arcgis.features import FeatureLayerCollection
from arcgis.features import FeatureCollection
import pandas as pd
import geopandas as gpd
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

if __name__ == "__main__":

    sde_connection = arcpy.GetParameterAsText(0)
    feature_service = arcpy.GetParameterAsText(1)
    layer_collection = FeatureLayerCollection(feature_service)
    first_layer = layer_collection.layers[0]
    # for lyr in layer_collection.layers:
    #     print(f"{lyr.properties.name} {lyr.properties.extent.spatialReference.wkid}")
    sdf = pd.DataFrame.spatial.from_layer(first_layer)
    print(sdf.spatial.geometry_type)
    name = first_layer.properties.name.replace(' ','_')
    schema = 'test'
    out_feature_class = sde_connection + "\\" + schema + "." + name
    # print(sdf.dtypes)
    sdf.spatial.to_featureclass(location=out_feature_class)
