'''
Explore options like pg_bulkload or pgloader for PostgreSQL

https://services7.arcgis.com/n1YM8pTrFmm7L4hs/arcgis/rest/services
'''
import re
import subprocess
import arcpy
import os
import csv
import json

import psycopg2
import requests
import tkinter as tk
from tkinter import simpledialog
import pandas as pd


def contains_any(text, values):
    """Checks if the text contains any of the values in the list."""
    return any(value in text for value in values)


text = "This is a string"
values = ["apple", "orange", "string"]

if contains_any(text, values):
    print("The text contains one of the values")
else:
    print("The text does not contain any of the values")


def camel_case(text):
    """
  Converts all caps to PascalCase (upper camel case).

  Args:
      text: The string to convert.

  Returns:
      The converted string in PascalCase.
  """
    return re.sub(r'[A-Z]{2,}', lambda match: match.group(0)[0] + match.group(0)[1:].lower(), text)


class parentConfigurationItem:
    def __init__(self, title, product, url, factsheet, products):
        self.title = title
        self.product = product
        self.url = url
        self.factsheet = factsheet
        self.base_products = products
        self.filters = filters

    def to_dict(self):
        return {
            'title': f"{self.title}",
            'card_image': f"usace-{self.product.lower()}.jpg",
            'parent_control': 'true',
            'security_classification': f"XXX-{self.product}-XXX",
            'mapServiceUrl': f"{self.url}",
            'factsheet': f"{self.factsheet}",
            'popup_config': {
                'title': f'{self.product}'
            },
            'products': [prod.to_dict() for prod in self.base_products]
        }


class productConfig:
    def __init__(self, base_products):
        self.base_products = base_products

    def to_dict(self):
        return {
            'baseProducts': [prod.to_dict() for prod in self.base_products]
        }


class popupConfig:
    def __init__(self, title, fields):
        self.title = title
        self.fields = fields

    def display(self):
        print(f"Name: {self.title}, Value: {self.fields}")

    def to_dict(self):
        return {
            'title': self.title,
            'fields': self.fields
        }


class ProductConfigItem:
    def __init__(self, title, cmb_mapserver_layer, popupConfig, filters):
        self.title = title
        self.cmb_mapserver_layer = cmb_mapserver_layer
        self.popup_config = popupConfig
        self.filters = filters

    def display(self):
        print(f"Name: {self.title}, Value: {self.cmb_mapserver_layer}")

    def to_dict(self):
        return {
            'title': self.title,
            'cmb_mapserver_layer': self.cmb_mapserver_layer,
            'security_classification': 'xxx-USACE-xxx',
            "product_filters": self.filters,
            'popup_config': self.popup_config.to_dict()
        }


def get_credentials():
    root = tk.Tk()
    root.withdraw()  # Hide the root window

    username = simpledialog.askstring("Credentials", "Enter your username:")
    password = simpledialog.askstring("Credentials", "Enter your password:", show='*')

    return username, password


def get_token(portal_url, username=None, password=None):
    if not username or not password:
        username, password = get_credentials()

    url = f"{portal_url}/sharing/rest/generateToken"
    params = {
        'f': 'json',
        'username': username,
        'password': password,
        'referer': portal_url,
        'expiration': 60  # Token expiration time in minutes
    }
    response = requests.post(url, data=params)
    if response.status_code == 200:
        token = response.json().get('token')
        return token
    else:
        raise Exception("Unable to get token")


def load_urls_from_db(host, dbname, user, password):
    # Connect to the PostgreSQL database
    conn = None
    cur = None
    try:
        conn = psycopg2.connect(dbname=dbname, user=user, password=password, host=host)

        # Create a cursor object
        cur = conn.cursor()

        # Build the SQL query with WHERE clause
        sql = f"SELECT collection_id,collection_name,urls,acronym,factsheet FROM catalog.product_configs"

        # Execute the query
        cur.execute(sql)

        # Fetch all the rows at once (adjust fetchall size based on data volume)
        rows = cur.fetchall()

        # Close the cursor and connection objects
        cur.close()
        conn.close()

        # Create a pandas DataFrame from the fetched data
        df = pd.DataFrame(rows, columns=["collection_id", "collection_name", "urls", "acronym", "factsheet"])

        return df

    except Exception as e:
        print(f"Error: {e}")
        return pd.DataFrame()  # Return empty DataFrame in case of errors
    finally:
        if cur is not None:
            cur.close()
        if conn is not None:
            conn.close()


def load_configs(location):
    conn = None
    try:
        # Connect to the PostgreSQL database
        path = os.path.join(location, 'product_config_data.csv')
        df = pd.read_csv(path, delimiter=',')
        return df;
    except Exception as e:
        print(e)


if __name__ == "__main__":
    output_location = arcpy.GetParameterAsText(0)
    host = arcpy.GetParameterAsText(1)
    dbname = arcpy.GetParameterAsText(2)
    user_name = arcpy.GetParameterAsText(3)
    password = arcpy.GetParameterAsText(4)
    if not user_name or not password:
        user_name, password = get_credentials()

    product_configs = load_urls_from_db(host, dbname, user_name, password)
    parentConfigList = []
    for index, row in product_configs.iterrows():
        acronym = row['acronym']
        collection_name = row['collection_name']
        factsheet = row['factsheet']
        urls = []
        if 'urls' in row and not isinstance(row['urls'], float):
            urls = row['urls'].strip().split(";")
        use_acronym = f" ({acronym})"
        if contains_any(acronym.upper(), ['BOUNDARIES', 'RESERVOIR', 'JURISDICTION']):
            use_acronym = ''

        name = f"{collection_name}{use_acronym}"
        name = name.replace(' Database', '')
        name = name.replace('System ', '')
        name = name.replace(' Framework', '')
        name = name.replace(' Support', '')
        productConfigList = []
        for base_url in urls:

            if base_url != '':

                try:
                    print(f"Requesting data from url for {acronym}")
                    response = requests.get(base_url, params={"f": "json"})
                    urlJson = response.json()

                    if "layers" in urlJson:
                        for child in urlJson["layers"]:

                            url = f'{base_url}/{child["id"]}'
                            print(f"Loading Layer: {child['name']} {child['geometryType']} {url}")
                            desc = arcpy.Describe(url)
                            names = [field.name for field in desc.fields]
                            title = child['name'].replace("_", " ")

                            ltitle = title.lower()
                            filters = []
                            if contains_any(ltitle, ["dam", "structure"]):
                                filters.append("Structures")
                            if contains_any(ltitle, ["dam", "levee", "reservoir"]):
                                filters.append("Dams")
                            if contains_any(ltitle,
                                            ["channel", "sea", "river", "canal", "harbour", "lake", "reservoir", "waterbody",
                                             "lock basin"]):
                                filters.append("WaterBodies")
                            if contains_any(ltitle, ["pipe"]):
                                filters.append("PipeLines")
                            if contains_any(ltitle, ["port", "linkton"]):
                                filters.append("Commerce")
                            if contains_any(ltitle, ["flood","inundation"]):
                                filters.append("Flood")
                            if contains_any(ltitle, ["dock"]):
                                filters.append("Docks")
                            if contains_any(ltitle, ["DIS","Dredg"]):
                                filters.append("Dredging")
                            if contains_any(ltitle, ["parcel","port","facility"]):
                                filters.append("Real Estate")
                            pConfig = ProductConfigItem(title, child['name'], popupConfig(child['name'], names),
                                                        filters)
                            productConfigList.append(pConfig)
                except Exception as e:
                    print(f"{e.message}")
        parentConfig = parentConfigurationItem(name, acronym, base_url, factsheet, productConfigList)
        parentConfigList.append(parentConfig)

    prodConfig = productConfig(parentConfigList)
    output_file_name = f"web-config-products.json"
    file_path = os.path.join(output_location, output_file_name)
    with open(file_path, 'w') as jsonfile:
        jsonfile.write(json.dumps(prodConfig.to_dict(), indent=4))
