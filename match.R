#/usr/bin/env Rscript
require('RPostgreSQL')
setwd('~/mxabierto/mg_inegi_postgis/')

# Establish connection to PoststgreSQL using RPostgreSQL
drv <- dbDriver("PostgreSQL")
# Full version of connection seetting
con <- dbConnect(drv, dbname="mg",host="192.168.99.100",port=5432,user="postgres",password="mysecretpassword")
df <- read.csv('test.csv',header=T)

c0 = 0
dfr <- matrix(nrow=0, ncol=5)
colnames(dfr) <- c('cve_ent','cve_mun','cve_loc','is_urban','rural_distance_m')
for (row in rownames(df)){
  cve_ent <-  as.numeric(df[row,"ENTIDAD"])
  cve_mun <-  as.numeric(df[row,"MUNICIPIO"])
  lat <- as.numeric(df[row,"LAT_D"])
  lon <- as.numeric(df[row,"LON_D"])
  query <- sprintf('SELECT
                   cve_ent,cve_mun,cve_loc ,ST_ContainsProperly(
                    geom,
                    ST_SetSRID(
                      ST_MakePoint(%5.3f,%5.3f),
                      96700
                      )
                   ) AS is_urban, (select(0)) as rural_distance_m FROM loc_urbanas
                   WHERE ST_ContainsProperly(
                    ST_GeomFromEWKB(geom),
                    ST_SetSRID(
                      ST_MakePoint(%5.3f,%5.3f),
                      96700
                      )
                   )=TRUE
                   AND cve_ent::INTEGER=%i
                   AND cve_mun::INTEGER=%i ;',lon,lat,lon,lat,cve_ent,cve_mun)
  rs <- dbSendQuery(con, query)
  dft <- fetch(rs, n = -1)
  if (nrow(dft)==0){
    query <- sprintf('SELECT
                   cve_ent,cve_mun,cve_loc, ( select(FALSE) ) as is_urban ,ST_Distance(
                    geom,
                    ST_SetSRID(
                      ST_MakePoint(%5.3f,%5.3f),
                      96700
                      )
                   ) AS rural_distance_m FROM loc_urbanas
                  WHERE cve_ent::INTEGER=%i
                  AND cve_mun::INTEGER=%i
                   ORDER BY ST_Distance(
                    geom,
                     ST_SetSRID(
                     ST_MakePoint(%5.3f,%5.3f),
                     96700
                     )) ASC LIMIT 1 ;',lon,lat,cve_ent,cve_mun,lon,lat)
    rs <- dbSendQuery(con, query)
    dft <- fetch(rs, n = -1)
  }
  dfr <- rbind(dfr,dft)
  df[row,'cve'] <- paste(dft$cve_ent,dft$cve_mun,dft$cve_loc, sep = '')
}

RPostgreSQL::dbDisconnect(conn = con)
