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
library(scales)


# setting up --------------------------------------------------------------
current_path <- rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path ))
print(getwd())

# read data ---------------------------------------------------------------

# state ID's 
gsod_my <- read_csv("GSOD_MY_DATA_COMBINED.csv") 

# data quality checks -----------------------------------------------------

describe(gsod_my) 

# aggregate data ---------------------------------------------------------


# temperature
gsod_my_temp_monthly <- gsod_my %>%
  mutate(year_month = floor_date(as_date(yearmoda), "month")) %>%
  group_by(stnid,name,year_month) %>%
  summarize(temp = mean(temp))

gsod_my_temp_yearly <- gsod_my %>%
  mutate(year = year(yearmoda)) %>%
  group_by(stnid,name,year) %>%
  summarize(temp = mean(temp))

# precipitation
gsod_my_prcp_monthly <- gsod_my %>%
  mutate(year_month = floor_date(as_date(yearmoda), "month")) %>%
  group_by(stnid,name,year_month) %>%
  summarize(prcp = sum(prcp,na.rm = T))

# plot data ---------------------------------------------------------------

# temperatures

# daily average temps
daily_temps_plot <- ggplot(data=gsod_my) +
  aes(x=yearmoda,y=temp) +
  geom_point(size=0.1) +
  facet_wrap(~name,nrow=8)

daily_temps_plot

# monthly average temps
monthly_temps_plot <- ggplot(data=gsod_my_temp_monthly) +
  aes(x=year_month,y=temp) +
  geom_point(size=0.1,alpha=0.25,fill="red",colour="red") +
  #geom_smooth(method="lm",size=0.5,col="red")+
  facet_wrap(~name,nrow=8) +
  scale_x_date(name="Year",labels=date_format("%Y")) +
  scale_y_continuous(name = "Temperature (Deg C)\n") +
  theme(text = element_text(family = "DM Sans"),
        #panel.background = element_rect(fill="white"), 
        axis.text.y=element_text(size=8,colour="grey20"),
        axis.text.x=element_text(size=8,colour="grey20"),
        axis.title.y=element_text(size=8,colour="grey20"),
        axis.title.x=element_text(size=8,colour="grey20"),
        strip.background =element_rect(fill="black"),
        strip.text = element_text(colour = 'white'))

monthly_temps_plot

ggsave(monthly_temps_plot,file="D:\\gsod_temps_plot.png",dpi=400,w=10,h=12,type="cairo-png")

# yearly average temps
yearly_temps_plot <- ggplot(data=gsod_my_temp_yearly) +
  aes(x=year,y=temp) +
  geom_point(size=0.1) +
  facet_wrap(~name,nrow=8)

yearly_temps_plot

# precipitation

# monthly prcp
monthly_prcp_plot <- ggplot(data=gsod_my_prcp_monthly) +
  aes(x=year_month,y=prcp) +
  geom_col(size=0.1) +
  #geom_smooth(method="lm",size=0.5,col="red")+
  facet_wrap(~name,nrow=8)

monthly_prcp_plot
