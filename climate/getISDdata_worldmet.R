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
library(nominatim) # library for geocoding stations using Mapquest
library(lubridate) # for time and date conversion
library(worldmet) # library to download ISD data - https://github.com/davidcarslaw/worldmet

# setting up --------------------------------------------------------------
current_path <- rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path ))
print(getwd())

# read data ---------------------------------------------------------------

# state ID's 
state_code <- read_csv("state_code.csv") %>%
  rename(state_code=code)

# get list of stations for Malaysia
stations_my <- 
  getMeta(plot=FALSE) %>%
  dplyr::filter(ctry == "MY") %>%
  mutate(start_year = year(begin),end_year = year(end)) %>%
  select(usaf,wban,station,ctry,call,latitude,longitude,start_year,end_year,code)

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
  select(usaf,wban,station,state,latitude,longitude,code) %>%
  mutate_if(is.character, str_to_upper) 

# pull data
# get unique usaf id's
usaf_ids <- stations_state_my %>%
  pull(as.numeric(code))

# create empty data frame
isd_df = data.frame()

# loop and download data
for (usaf_id in usaf_ids) {

  station_id <- 
  stations_my %>%
  filter(code == usaf_id) %>%
  dplyr::pull(code) 
  
  station_data <- importNOAA(code = usaf_id, year = filter(stations_my,code==usaf_id)[[8]]:filter(stations_my,code==usaf_id)[[9]])
  
  isd_df <- rbind(isd_df,station_data)

}

# join with state information
isd_comb_df <- isd_df %>%
  left_join(select(stations_state_my,code,state),by="code") %>%
  left_join(state_code,by=c("state"="name")) %>%
  mutate(datetime = as.POSIXlt(date, tz="Asia/Kuala_Lumpur")) %>%
  select(-date,-category) %>%
  filter(datetime < ymd("2022-01-01")) # filter data up to specific date

# split dataframe by state
split_df <- split(isd_comb_df, list(isd_comb_df$state,"_",isd_comb_df$code))

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
write_csv(isd_comb_df,"ISD_MY_DATA_COMBINED.csv")

# write station info to csv
stations_my_info <- stations_state_my %>%
  left_join(select(stations_my,usaf,start_year,end_year),by="usaf") %>%
  relocate(code,.before=usaf)

write_csv(stations_my_info,"ISD_MY_STATIONS_INFO.csv")
            