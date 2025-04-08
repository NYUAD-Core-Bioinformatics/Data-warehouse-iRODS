# Data-warehouse-iRODS

This setups includes iRODS v4.3.1 and this needs to run on a blade server and postgres is needed to run as standalone. 

Technologies Used
iRODS 4.3.1
Docker >=26
Python >=3.11

Refer, irods official documentation for the installation part. 

Note:- postgres cannot be containerzied due to performance issues. 

The next part is the data collection, create json structure and then import these data ingested to the irods catalogue without mounting the real data. So we need to create the similiar directory structure on the irods running server. 

- Data Collection
Generate the list of files with the size by below command. Here our data resides in the HPC archive node. So i need to use the ```dmfdu`` custom utility get the size of file. 

```
find <path-to-files/directory>  -type f -exec ls -l {} + | awk '{print $9}' > input.txt
for i in `cat input.txt`; do printf $i" ";dmfdu $i | sed s/\ //g; done | awk '{print $2" " $1}' > out.txt
```

- Create json structure
Then using the ```out.txt``` file, then supply this as input to the perl script. As this will generate the json needed for python script to supply as input and directory creation shell script to frame the structure before supplying the python script. 

```
perl Create_IrodesJson.pl out.txt
```

- Ingest metadata to iRODS catalog

The first task is to create the directory and file structure similiar to the HPC cluster to the irods running server
```
sh makedir.sh

Then supply the data ingest command to feed the metadata to the iRODS catalog.
```
python data_ingest.py <path-to-json-file>
```

Then to view the ingested data, use either irods CLI or using iRODS Web GUI.

Switch to the ```irods-gui``` directory and then try to edit the irods login details and update docker-com

```
cd irods-gui
vim metalnx-configuration/metalnxConfig.xml 
```

Invoke the docker install

```
docker compose up -d 
```

You can access the GUI, login with the irods credentials. Then navigate to collections and explore/browse the data.

```
http://example.com/metalnx/login/
```

#### Future plans:- 

- Efficiently remove the modified files from the irods catalog
- Remove files using the metadata json file.

## Other Useful Links

- [iRODS](https://irods.org/) 
