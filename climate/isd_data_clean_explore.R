## ------------------------------------------------------------------------
##
## Purpose of script: Clean and explore weather data for Malaysia from ISD (Integrated Surface Database)
##
## Author: Jason Benedict
##
## Date Created: 2022-06-15
## 
## ------------------------------------------------------------------------
##
## Notes:   
##
## ------------------------------------------------------------------------

options(scipen = 6, digits = 4) # I prefer to view outputs in non-scientific notation

## load packages ----------------------------------------------------------
library(tidyverse)
library(lubridate) # for time and date conversion
library(explore)


# setting up --------------------------------------------------------------
current_path <- rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path ))
print(getwd())

# read data ---------------------------------------------------------------

# state ID's 
isd_my <- read_csv("ISD_MY_DATA_COMBINED.csv") 

# data quality checks -----------------------------------------------------

describe(isd_my) 

# clean data --------------------------------------------------------------

isd_my_clean <- isd_my %>%
  mutate(year = year(datetime)) %>%
  filter(air_temp > 20 & year < 2022) # removing air temperatures less than 23 deg C

# aggregate data ---------------------------------------------------------

isd_my_daily <- isd_my_clean %>%
  mutate(date = date(datetime)) %>%
  group_by(code,station,date) %>%
  summarize(air_temp = mean(air_temp))

isd_my_monthly <- isd_my_clean %>%
  mutate(year_month = floor_date(as_date(datetime), "month")) %>%
  group_by(code,station,year_month) %>%
  summarize(air_temp = mean(air_temp))

isd_my_yearly <- isd_my_clean %>%
  mutate(year = year(datetime)) %>%
  group_by(code,station,year) %>%
  summarize(air_temp = mean(air_temp))

# plot data ---------------------------------------------------------------

# daily average temps
daily_temps_plot <- ggplot(data=isd_my_daily) +
  aes(x=date,y=air_temp) +
  geom_point()

daily_temps_plot

# monthly average temps
monthly_temps_plot <- ggplot(data=isd_my_monthly) +
  aes(x=year_month,y=air_temp,color=station) +
  #geom_point() +
  geom_line()

monthly_temps_plot

# yearly average temps
yearly_temps_plot <- ggplot(data=isd_my_yearly) +
  aes(x=year,y=air_temp,color=station) +
  geom_point() +
  geom_line()

yearly_temps_plot
