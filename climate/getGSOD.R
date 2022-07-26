## ------------------------------------------------------------------------
##
## Purpose of script: Read weather data for Malaysia from GSOD (Global Summary of the Day)
##                    and write to individual csv files for every station in each state
##
## Author: Jason Benedict
##
## Date Created: 2022-06-15
## 
## ------------------------------------------------------------------------
##
## Notes:   > GSOD website - https://www.ncei.noaa.gov/access/metadata/landing-page/bin/iso?id=gov.noaa.ncdc:C00516
##
##          > More information on NOAA's Global Summary of the Day format can be found
##            https://www.ncei.noaa.gov/data/global-summary-of-the-day/doc/readme.txt
##
##
## ------------------------------------------------------------------------

options(scipen = 6, digits = 4) # I prefer to view outputs in non-scientific notation

## load packages ----------------------------------------------------------
library(tidyverse)
library(nominatim) # library for geocoding stations using Mapquest
library(lubridate) # for time and date conversion
library(GSODR) # library to download GSOD data - https://github.com/ropensci/GSODR

# setting up --------------------------------------------------------------
current_path <- rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path ))
print(getwd())
load(system.file("extdata", "isd_history.rda", package = "GSODR"))
my <- subset(isd_history, COUNTRY_NAME == "MALAYSIA")

# read data ---------------------------------------------------------------

# state ID's 
state_code <- read_csv("state_code.csv") %>%
  rename(state_code=code)

# get list of stations for Malaysia
stations_my <- 
  isd_history %>%
  dplyr::filter(COUNTRY_NAME == "MALAYSIA") %>%
  mutate(start_year = substr(as.character(BEGIN),1,4),end_year = substr(as.character(END),1,4)) %>%
  select(code=STNID,name=NAME,latitude=LAT,longitude=LON,start_year,end_year) 

# geocode stations to get states
latlong <- stations_my %>% 
  select(latitude, longitude) %>% 
  unique() %>% 
  mutate(index=row_number())

key = "<MAPQUEST KEY>" # register at https://developer.mapquest.com/ to get your API key

coords <- reverse_geocode_coords(latlong$latitude,latlong$longitude,key=key)

states <- coords %>% 
  mutate(index = row_number()) %>%
  select(index,state) %>% 
  left_join(latlong, by="index") %>% 
  select(-index)

stations_state_my <- stations_my %>% 
  left_join(states, by=c("latitude","longitude")) %>% 
  select(name,state,latitude,longitude,code) %>%
  mutate_if(is.character, str_to_upper) %>%
  filter(!is.na(state))

# pull data
# get unique usaf id's
usaf_ids <- stations_state_my %>%
  pull(as.numeric(code))

# create empty data frame
gsod_df = data.frame()

# loop and download data
for (usaf_id in usaf_ids) {

  station_id <- 
  stations_my %>%
  filter(code == usaf_id) %>%
  dplyr::pull(code) 
  
  station_data <- get_GSOD(years = filter(stations_my,code==usaf_id)[[5]]:filter(stations_my,code==usaf_id)[[6]], station = usaf_id)
  
  gsod_df <- rbind(gsod_df,station_data)

}

# join with state information
gsod_comb_df <- gsod_df %>%
  select(-STATE,-COUNTRY_NAME,-ISO2C,-ISO3C) %>%
  janitor::clean_names() %>%
  left_join(select(stations_state_my,code,state),by=c("stnid"="code")) %>%
  left_join(state_code,by=c("state"="name")) 

# split dataframe by state
split_df <- split(gsod_comb_df, list(gsod_comb_df$state,"_",gsod_comb_df$stnid))

# remove empty lists
split_df <- Filter(function(x) dim(x)[1] > 0, split_df)
# remove periods in list names
names(split_df) <- gsub("\\.", "", names(split_df))


## export data --------------------------------------------------------

# write out separate CSV for each station
for (state in names(split_df)) {
  write_csv(split_df[[state]], paste0(state, ".csv"))
}

# write merged output file
write_csv(gsod_comb_df,"GSOD_MY_DATA_COMBINED.csv")

# write station info to csv
stations_my_info <- stations_state_my %>%
  left_join(select(stations_my,code,start_year,end_year),by="code") %>%
  relocate(code,.before=name)

write_csv(stations_my_info,"GSOD_MY_STATIONS_INFO.csv")
            