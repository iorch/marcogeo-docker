#!/bin/sh

set -e

# Perform all actions as user 'postgres'
export PGUSER=postgres
export PGDATA=$PGDATA

# Create the 'mg' template db
psql <<EOSQL
CREATE DATABASE mg;
UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'mg';
EOSQL

# Populate 'template_postgis'
cd /usr/share/postgresql/$PG_MAJOR/contrib/postgis-$POSTGIS_MAJOR
psql --dbname mg < postgis.sql
psql --dbname mg < topology.sql
psql --dbname mg < spatial_ref_sys.sql
psql --dbname mg -c "CREATE EXTENSION hstore;"
psql -d mg -c "INSERT into spatial_ref_sys
    (srid, auth_name, auth_srid, proj4text, srtext)
    values
    ( 96700,
      'sr-org',
       6700,
       '+proj=lcc +lat_1=17.5 +lat_2=29.5 +lat_0=12 +lon_0=-102 +x_0=2500000 +y_0=0 +a=6378137 +b=6378136.027241431 +units=m +no_defs ',
        'PROJCS[\"unnamed\",
          GEOGCS[\"WGS 84\",
            DATUM[\"unknown\",
              SPHEROID[\"WGS84\",6378137,6556752.3141]],
            PRIMEM[\"Greenwich\",0],
            UNIT[\"degree\",0.0174532925199433]],
          PROJECTION[\"Lambert_Conformal_Conic_2SP\"],
          PARAMETER[\"standard_parallel_1\",17.5],
          PARAMETER[\"standard_parallel_2\",29.5],
          PARAMETER[\"latitude_of_origin\",12],
          PARAMETER[\"central_meridian\",-102],
          PARAMETER[\"false_easting\",2500000],
          PARAMETER[\"false_northing\",0]
        ]'
    );"
cd /
mkdir scripts

for file in `ls -1 /data/*.shp`; do
  table_name=''
  file=`echo ${file}| sed 's/\/data\///'`
  echo $file
  case ${file:0:4} in
    mge2) table_name='entidades'
    ;;
    mglr) table_name='loc_rurales'
    ;;
    mglu) table_name='loc_urbanas'
    ;;
    mgm2) table_name='municipios'
    ;;
  esac
  script=`echo ${file}|sed 's/data//'`
  shp2pgsql -I -WLATIN1 -s 96700 -g geom -p /data/${file} ${table_name} \
    > scripts/${script}'_c.sql'
  shp2pgsql -I -WLATIN1 -s 96700 -g geom -a /data/${file} ${table_name} \
    > scripts/${script}'.sql'
      psql -d mg -f scripts/${script}'_c.sql'
      psql -d mg -f scripts/${script}'.sql'
done
