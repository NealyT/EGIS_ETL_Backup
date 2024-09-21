import requests
import json
import arcpy
import logging
import pandas as pd
import os
import subprocess


def convertCSVToGeoJson(ogr_location, output_location, name):
    file_path = os.path.join(output_location, f"{name}.geojson")
    file_path2 = os.path.join(output_location, f"{name}.csv")

    command = [
        ogr_location,
        "-f", "GeoJSON",  # Output format
        file_path,  # Input GeoJSON file
        file_path2,  # Name of the output layer (table)
        '-s_srs', 'EPSG:4326',
        '-t_srs', 'EPSG:4326'

    ]
    print(command)
    #
    # # Run ogr2ogr as a subprocess
    try:
        subprocess.check_call(command)
        print("File conversion successful!")
        return file_path
    except Exception as error:
        print(f"Error during ogr2ogr execution: {error}")

def convertEsriJsonToGeoJson(ogr_location, output_location, name):
    file_path = os.path.join(output_location, f"{name}.geojson")
    file_path2 = os.path.join(output_location, f"{name}.json")

    command = [
        ogr_location,
        "-f", "GeoJSON",  # Output format
        file_path,  # Input GeoJSON file
        file_path2  # Name of the output layer (table)
    ]
    print(command)
    #
    # # Run ogr2ogr as a subprocess
    try:
        subprocess.check_call(command)
        print("File conversion successful!")
        return file_path
    except Exception as error:
        print(f"Error during ogr2ogr execution: {error}")


def saveGeoJson(name, featureLayer, output_location):
    # Define the output location and file name
    file_path = None

    try:
        output_file_name = f"{name}.geojson"

        print(f'Saving file {output_location}/{name}.geojson...')
        file_path = os.path.join(output_location, output_file_name)

        with open(file_path, 'w', encoding='utf-8') as file:
            if hasattr(featureLayer, 'GeoJSON'):
                file.write(featureLayer.GeoJSON)

        print(f"Data exported successfully to {output_location}\\{output_file_name}")
    except Exception as e:
        print(e)
        print(f"Problem generating geojson file {file_path}")
    return file_path

def saveJson(name, input_json, output_location):
    # Define the output location and file name
    file_path = None

    try:
        output_file_name = f"{name}.json"

        print(f'Saving file {output_location}/{name}.json...')
        file_path = os.path.join(output_location, output_file_name)

        with open(file_path, 'w', encoding='utf-8') as file:
            json.dump(input_json, file)

        print(f"Data exported successfully to {output_location}\\{output_file_name}")
    except Exception as e:
        print(e)
        print(f"Problem generating geojson file {file_path}")
    return file_path

# url = "https://cwms-data.usace.army.mil/cwms-data/offices"
# url = "https://nid.sec.usace.army.mil/api/metadata"
url = "https://cwms-data.usace.army.mil/cwms-data/catalog/LOCATIONS"
logger = logging.getLogger(__name__)

stream_handler = logging.StreamHandler()
logger.setLevel(logging.DEBUG)
logger.addHandler(stream_handler)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
stream_handler.setFormatter(formatter)

logger.debug("Starting Process")
ogr_location = r"C:\Program Files\QGIS 3.38.0\bin\ogr2ogr.exe"
page = 1
has_next_page = True
all_data=[]
try:
    output_location = r"d:\\data\CWMS"
    sde_connection = arcpy.GetParameterAsText(0)
    headers = {'Accept': 'application/json;version=2'}
    pdata = {"limit_count": 1000, "limit_size": 10000}


    response = requests.get(url, headers=headers)
    response_json = response.json()
    response.raise_for_status()
    data = json.loads(response.text)
    all_data.extend(data["entries"])
    print(data["entries"][0])
    has_next_page = True
    params = {}
    while has_next_page:
        response = requests.get(url, params=params, headers=headers)
        response_json = response.json()
        data = json.loads(response.text)
        all_data.extend(data["entries"])
        print(data["entries"][0])
        print(len(all_data))
        has_next_page = "next-page" in response_json
        if has_next_page:
            params = {'page': response_json["next-page"]}
        else:
            has_next_page = "page" in response_json
            if has_next_page:
                params = {'page': response_json["page"]}
    # https://cwms-data.usace.army.mil/cwms-data/catalog/LOCATIONS?page=1
    print(len(all_data))
    df = pd.DataFrame.from_records(all_data)
    # df.columns = ['name', "long_name","type","reports_to"]
    df.to_csv('d:\\data\CWMS\cwms_location_point.csv', index=False)
    # child_data = {
    #     "type": "FeatureCollection",
    #     "features": data["entries"][1:]  # Assuming 'featureset' is a list of GeoJSON features
    # }
    #
    # saveJson("cwms_location_point", child_data, output_location)
    convertCSVToGeoJson(ogr_location, output_location, "cwms_location_point")

    #
    # print(df)

    logger.debug("Process Completed")
except requests.exceptions.SSLError as e:
    print(f"SSL Error: {e}")


# Now 'all_data' contains all the retrieved data in JSON format
