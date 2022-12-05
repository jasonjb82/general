## ---------------------------------------------------------
##
## Purpose of script: Scrape EIA list from GEOSPAS DoE Malaysia geoserver and export to csv file
##
## Author: Jason Benedict
##
## Date Created: 2022-07-26
## 
## ---------------------------------------------------------
##
## Notes:
##   
##
## ---------------------------------------------------------

options(scipen = 6, digits = 4) # I prefer to view outputs in non-scientific notation

## ---------------------------------------------------------

# load required libraries
library(esri2sf) # install from here - https://github.com/yonghah/esri2sf
library(rgdal)
library(sf)
library(tidyverse)

# set location to download files
setwd("D:/")

# set url
url <- "https://geospas.doe.gov.my/jarvis02/rest/services/DataEIA/EIA_ALL_live/MapServer/0"

# convert to df
df <- esri2sf(url)

# clean up date
df_clean <- df %>%
  mutate(TARIKH_KEPUTUSAN_PROPER = as.Date(as.POSIXct(TARIKH_KEPUTUSAN/1000, origin="1970-01-01",tz = "Asia/Kuala_Lumpur"))) %>%
  select(-TARIKH_KEPUTUSAN) %>%
  st_drop_geometry() %>%
  as_tibble() %>%
  glimpse()

# get scrape date
date = format(Sys.time(), "%Y%m%d")

# write to csv
write_csv(df_clean,paste0("eia_geospas_doe_",date,".csv"))
