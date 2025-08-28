# Data-warehouse-iRODS

This setups includes iRODS v5.0.1 and this needs to run on a blade server and postgres is needed to run as standalone. 

Environment:- 
iRODS 5.0.1
RHEL 9.6
Docker >=26
Python >=3.11

- Installing Postgres 

```
dnf install postgresql-server postgresql-contrib postgresql
postgresql-setup --initdb
```

Postgres custom config for the improved performance. 
```
mv /var/lib/pgsql/data/postgresql.conf /var/lib/pgsql/data/postgresql.conf-bkp
vim /var/lib/pgsql/data/postgresql.conf
dynamic_shared_memory_type = posix	# the default is the first option
logging_collector = on			# Enable capturing of stderr and csvlog
log_filename = 'postgresql-%a.log'	# log file name pattern,
log_truncate_on_rotation = on		# If on, an existing log file with the
log_rotation_age = 1d			# Automatic rotation of logfiles will
log_rotation_size = 0			# Automatic rotation of logfiles will
log_timezone = 'Asia/Dubai'
datestyle = 'iso, mdy'
timezone = 'Asia/Dubai'
lc_messages = 'en_US.UTF-8'			# locale for system error message
lc_monetary = 'en_US.UTF-8'			# locale for monetary formatting
lc_numeric = 'en_US.UTF-8'			# locale for number formatting
lc_time = 'en_US.UTF-8'				# locale for time formatting
default_text_search_config = 'pg_catalog.english'

#Custom config
max_connections = 40
shared_buffers = 128512MB
effective_cache_size = 385536MB
maintenance_work_mem = 2GB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 500
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 822476kB
huge_pages = try
min_wal_size = 4GB
max_wal_size = 16GB

```

Add below line to the below file.
```
vim /var/lib/pgsql/data/pg_hba.conf
host    all             all             127.0.0.1/32               md5
```

Start and enable postgresql at boot.
```
systemctl enable postgresql
systemctl restart postgresql
```

Create database and user for postgres
```
su - postgres
psql
CREATE DATABASE "ICAT";
CREATE USER irods WITH PASSWORD 'testpassword';
GRANT ALL PRIVILEGES ON DATABASE "ICAT" to irods;
ALTER DATABASE "ICAT" OWNER TO irods;
\q
```

- Installing iRODS

Optional:- If you need to stick to v4.3.1, then issue below. Otherwise skip this step.
```
dnf install irods-externals-zeromq4-14.1.8-0-1.0-1.x86_64 irods-externals-nanodbc2.13.0-1-1.0-1.x86_64 irods-externals-libarchive3.5.2-0-1.0-1.x86_64 irods-externals-fmt8.1.1-0-1.0-1.x86_64 irods-externals-clang-runtime13.0.0-0-1.0-1.x86_64 irods-externals-boost1.81.0-0-1.0-1.x86_64 irods-externals-avro1.11.0-2-1.0-1.x86_64 irods-runtime-4.3.1-0.el9.x86_64 irods-server-4.3.1-0.el9.x86_64 irods-database-plugin-postgres-4.3.1-0.el9 irods-icommands-4.3.1-0.el9
```

Install the latest version of iRODS (5.0.1)
```
dnf install epel-release
dnf install irods-server irods-database-plugin-postgres irods-icommands
```

Initialize the irods configuration
```
python3 /var/lib/irods/scripts/setup_irods.py
-------------------------------------------------------------
Database Type:        postgres
Database ODBC Driver: PostgreSQL
Database Host:        localhost
Database Port:        5432
Database Name:        ICAT
Database Username:    irods
-------------------------------------------------------------
Salt for passwords stored in the database:
Local storage on this server [yes]:
Default resource [demoResc]:
iRODS vault directory [/var/lib/irods/Vault]:
-------------------------------------------------------------
iRODS Zone Name:                            tempZone
iRODS Zone Port:                            1247
iRODS Parallel Transfer Port Range (begin): 20000
iRODS Parallel Transfer Port Range (end):   20199
iRODS Administrator:                        rods
-------------------------------------------------------------
Please confirm [yes]:
iRODS zone key:irods
iRODS negotiation key (32 characters):AbcDef1234567890AbcDef1234567890
```
Record the credential in the home directory to record the login information for iRods CLI.
```
iinit
```

Systemd unit file for autostart up.
```
$cat /usr/lib/systemd/system/irods.service
[Unit]
Description=iRODS
After=network.target

[Service]
RuntimeDirectory=irods
RuntimeDirectoryMode=0755
Type=notify-reload
ExecStart=/usr/sbin/irodsServer
KillMode=mixed
Restart=on-failure
User=irods
Group=irods
WorkingDirectory=/var/lib/irods
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
```

Note:- postgressql cannot be containerzied due to performance issues. 

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

The first task is to create the directory and file structure similiar to the HPC cluster in the irods running server.
```
sh makedir.sh
```

- Prepare the necessary irods resource and register the directory structure. As of now we have 3 set of data collection in the irods.

```
1)
iadmin mkresc im2493_Resc unixfilesystem varseq.abudhabi.nyu.edu:/home/im2493/Imane_VarSeq
ireg -r   /home/im2493/Imane_VarSeq /tempZone/home/rods/Imane_VarSeq

2)
iadmin mkresc Genotyping unixfilesystem varseq.abudhabi.nyu.edu:/Genotyping
ireg -r -f   /Genotyping  /tempZone/home/rods/Genotyping

3)
iadmin mkresc G42_WGS unixfilesystem varseq.abudhabi.nyu.edu:/G42_WGS
ireg -r -f   /G42_WGS  /tempZone/home/rods/G42_WGS
```

Then supply the data ingest command to feed the metadata to the iRODS catalog.

```
pip install python-irodsclient
python data_ingest.py <path-to-json-file>
```

To view the ingested data in irods then, 
```
ils -r -L -A 
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
http://varseq.abudhabi.nyu.edu/metalnx/login/
```

#### Future plans:- 

- Efficiently remove the modified files from the irods catalog
- Remove files using the metadata json file.

## Other Useful Links

- [iRODS](https://irods.org/) 
