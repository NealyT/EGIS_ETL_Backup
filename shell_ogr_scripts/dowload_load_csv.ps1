# Define variables
$url = "https://nid.sec.usace.army.mil/api/nation/csv"
$outputPath = "D:\data\bah\NID\nation.csv"
database = "egis_bah"
user = "catg"
password = "catg123"
table = "nid.dams_ads"
host = "localhost"

# 1. Download the CSV file using wget
Invoke-WebRequest -Uri $url -OutFile $outputPath

# 2. Remove the first line of the file
(Get-Content $outputPath | Select-Object -Skip 1) | Set-Content $outputPath

# 3. Use ogr2ogr to load the CSV file into PostgreSQL
# Note: Ensure that ogr2ogr is in your system PATH or provide the full path to ogr2ogr.exe

ogr2ogr -f "PostgreSQL" PG:"host=$host dbname=$database user=$user password=$password" $outputPath -nln $table -overwrite -oo HEADERS=YES
