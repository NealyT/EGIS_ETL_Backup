
import pandas as pd
from arcgis.features import GeoAccessor, GeoSeriesAccessor
import json
import geopandas as gpd

# Read GeoJSON file
with open('your_geojson_file.geojson', 'r') as f:
    geojson_data = json.load(f)

# Create GeoPandas GeoDataFrame
gdf = gpd.GeoDataFrame.from_features(geojson_data['features'])

# Convert to SEDF
sedf = GeoAccessor.from_geodataframe(gdf, column_name='geometry')

print(sedf.head())