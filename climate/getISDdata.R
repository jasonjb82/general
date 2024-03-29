## ------------------------------------------------------------------------
##
## Purpose of script: Read weather data for Malaysia from ISD (Integrated Surface Database)
##                    and write to individual csv files for every station in each state
##
## Author: Jason Benedict
##
## Date Created: 2020-06-14
## 
## ------------------------------------------------------------------------
##
## Notes:   > Integrated Surface Dataset website - https://www.ncdc.noaa.gov/isd
##
##          > More information on NOAA's Integrated Surface Database format can be found
##            at the following link - https://www1.ncdc.noaa.gov/pub/data/ish/ish-format-document.pdf
##
##          > Weather variables in each file is as shown at the following link - 
##            https://rich-iannone.github.io/stationaRy/reference/get_met_data.html
##
## ------------------------------------------------------------------------

options(scipen = 6, digits = 4) # I prefer to view outputs in non-scientific notation

## load packages ----------------------------------------------------------
library(tidyverse)
library(stationaRy) # library to download ISD data -https://github.com/rich-iannone/stationaRy
library(nominatim) # library for geocoding stations using Mapquest
library(lubridate) # for time and date conversion

# setting up --------------------------------------------------------------
current_path <- rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path ))
print(getwd())

# read data ---------------------------------------------------------------

# state ID's 
state_code <- read_csv("state_code.csv")

# get list of stations for Malaysia
stations_my <- 
  get_station_metadata() %>%
  dplyr::filter(country == "MY") %>%
  filter(str_detect(tz_name, "^Asia/")) %>%
  select(id,usaf,icao,name,lat,lon,begin_year,end_year,begin_date,end_date)

# geocode stations to get states
latlong <- stations_my %>% 
  select(lat, lon) %>% 
  unique() %>% 
  mutate(index=row_number())

key = "<MAPQUEST KEY>" # register at https://developer.mapquest.com/ to get your API key

coords <- reverse_geocode_coords(latlong$lat,latlong$lon,key=key)

states <- coords %>% 
  mutate(index = row_number()) %>%
  select(index,state) %>% 
  left_join(latlong, by="index") %>% 
  select(-index)

stations_state_my <- stations_my %>% 
  left_join(states, by=c("lat","lon")) %>% 
  select(id,usaf,name,state,lat, lon) %>%
  mutate_if(is.character, str_to_upper) 

# pull data
# get unique usaf id's
usaf_ids <- stations_state_my %>%
  pull(as.numeric(usaf))

# create empty data frame
isd_df = data.frame()

# loop and download data
for (usaf_id in usaf_ids) {

  station_data <- 
  get_station_metadata() %>%
  filter(usaf == usaf_id) %>%
  dplyr::pull(id) %>%
  get_met_data(years = filter(stations_my,usaf == usaf_id)[[7]]:filter(stations_my,usaf == usaf_id)[[8]])
  
  isd_df <- rbind(isd_df,station_data)

}

# join with state information
isd_comb_df <- isd_df %>%
  left_join(stations_state_my,by="id") %>%
  left_join(state_code,by=c("state"="name")) %>%
  select(-category) %>%
  filter(time < ymd_hms("2021-01-01 00:00:00")) # filter data up to 2019

# split dataframe by state
split_df <- split(isd_comb_df, list(isd_comb_df$state,"_",isd_comb_df$id))

# remove empty lists
split_df <- Filter(function(x) dim(x)[1] > 0, split_df)
# remove periods in list names
names(split_df) <- gsub("\\.", "", names(split_df))


## export data --------------------------------------------------------

# write out separate CSV for each station
for (state in names(split_df)) {
  write.csv(split_df[[state]], paste0(state, ".csv"),row.names = FALSE)
}

# write station info to csv
stations_my_info <- stations_state_my %>%
  left_join(select(stations_my,usaf,icao,begin_year,end_year),by="usaf") %>%
  relocate(icao,.before=usaf)

write_csv(stations_my_info,"ISD_MY_STATIONS_INFO.csv")
            