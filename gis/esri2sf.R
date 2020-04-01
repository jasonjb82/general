# load required libraries
library(esri2sf)
library(rgdal)

# set location to dowload files
setwd("C:/Users/Jason/Desktop/")

# set url
url <- "https://services3.arcgis.com/mKcWKyEU5Tl36xeT/ArcGIS/rest/services/RSPO_Concession_270320/FeatureServer/0"

# convert to df
df <- esri2sf(url)

# convert to spdf
spdf = as(df, 'Spatial')

# write out a new shapefile (including .prj component)
st_write(df, "RSPO_Concession_270320.shp")
