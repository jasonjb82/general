# load required libraries
library(esri2sf)
library(rgdal)

# set location to dowload files
setwd("C:/Users/Jason/Desktop/")

# set url
url <- "https://gis.wwf.id/server/rest/services/National/Kawasan_Hutan_Indonesia_KLHK_2014/MapServer/0"

# convert to df
df <- esri2sf(url)

# convert to spdf
spdf = as(df, 'Spatial')

# write out a new shapefile (including .prj component)
st_write(df, "national.natdbo.Kawasan_Hutan_Indonesia_KLHK_2014.shp")
