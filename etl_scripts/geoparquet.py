import geopandas as gpd
import os
import pyarrow as pa
import pyarrow.parquet as pq
import fiona
import pandas as pd
print(fiona.__version__)  # Check Fiona version
# Path to your File Geodatabase
gdb_path = r'D:\Users\nealie.t\Documents\ArcGIS\Projects\EGIS_Server_Project\ib.gdb'

# Output directory for GeoParquet files
output_dir = 'output_geo_parquet'
outpath =os.path.join(r'D:\Users\nealie.t\Documents\ArcGIS\Projects\EGIS_Server_Project',output_dir)
os.makedirs(outpath, exist_ok=True)
# List all layers in the GDB
layers = fiona.listlayers(gdb_path)
gdf_list=[]
# Iterate over each layer and convert it to GeoParquet
for layer in layers:
    try:
        # Read the layer into a GeoDataFrame
        gdf = gpd.read_file(gdb_path, layer=layer)

        # Define the output GeoParquet file path
        output_file = os.path.join(outpath, f"{layer}.parquet")

        # Write the GeoDataFrame to a GeoParquet file
        gdf.to_parquet(output_file, index=False)

        if gdf.crs != "EPSG:4326":
            gdf = gdf.to_crs("EPSG:4326")
        print(f"Successfully saved {layer} as {output_file}")
        gdf['source_layer'] = layer

        # Append the GeoDataFrame to the list
        gdf_list.append(gdf)

    except Exception as e:
        print(f"Failed to process {layer}: {e}")


combined_gdf = pd.concat(gdf_list, ignore_index=True)

output_file = os.path.join(outpath,'combined_layers.parquet')

# Save the combined GeoDataFrame as a single GeoParquet file
combined_gdf.to_parquet(output_file, index=False)