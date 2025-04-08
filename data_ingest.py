#This script runs with as an first argument
#python data_ingest.py <path-to-json-file>
import sys
import json
from irods.exception import DataObjectDoesNotExist
from irods.session import iRODSSession

# Connection settings
irods_host = 'localhost'
irods_port = 1247
irods_user = 'rods'
irods_password = 'xxxxx'
irods_zone = 'tempZone'


# Read metadata information from JSON
with open(sys.argv[1], 'r') as metadata_file:
    metadata_info = json.load(metadata_file)

# Establish iRODS session
with iRODSSession(host=irods_host, port=irods_port, user=irods_user, password=irods_password, zone=irods_zone) as session:
    for entry in metadata_info:
        remote_irods_path = entry['path']
        metadata = entry['metadata']

        try:
            # Create a data object
            data_object = session.data_objects.create(remote_irods_path)

            # Add metadata from the JSON
            for key, value in metadata.items():
                data_object.metadata.add(key, value)

            # Print the path
            print("Path:", remote_irods_path)

        except DataObjectDoesNotExist:
            print(f"File '{remote_irods_path}' already exists in iRODS. Skipping metadata addition for this file.")

        # Exit the loop after processing the first entry

print("Data objects created in iRODS with metadata.")
