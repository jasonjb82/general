## ---------------------------
##
## Purpose of script: Read and plot sea level data from UHSLC SOEST Hawaii
##
## Author: Jason Benedict
##
## Date Created: 2020-06-23
## 
## ---------------------------
##
## Notes:
##   
##
## ---------------------------

options(scipen = 6, digits = 4) # I prefer to view outputs in non-scientific notation

## ---------------------------

## load packages

library(tidyverse)
library(readxl)
library(tidylog)
library(data.table)
library(janitor)
library(lubridate)
library(myutil)
library(sf)
library(scales)

## set working directory


## read data

png <- read_csv("http://uhslc.soest.hawaii.edu/data/csv/rqds/indian/hourly/h144a.csv",col_names = FALSE)


png_df <- png %>%
  rename(year=X1,month=X2,day=X3,hour=X4,level_mm=X5) %>%
  mutate(datetime=make_datetime(year,month,day,hour)) %>%
  filter(level_mm > 0)


png_yr <- png_df %>%
  group_by(year) %>%
  summarize(yr_level_mm = mean(level_mm))

png_yr_mth <- png_df %>%
  mutate(month = str_pad(month,width=2,side="left",pad="0")) %>%
  mutate(year_mth = paste(year,month,sep="-")) %>%
  group_by(year_mth) %>%
  summarize(yr_level_mm = mean(level_mm))

## Plot Sea Level

png_sl <- ggplot(png_df, aes(datetime, level_mm))+
  #geom_line(size=0.5)+
  geom_point(shape=5,size=1)+
  #geom_smooth(method="lm",size=0.5,col="red")+
  scale_x_datetime(name="",labels=date_format("%Y"),breaks = date_breaks("2 years"))+
  ylab("Milimetres (mm)\n")+
  xlab("\nYear")+
  theme_bw()+
  ggtitle("")+
  theme(plot.title = element_text(lineheight=1.2, face="bold",size = 14, colour = "grey20"),
        panel.border = element_rect(colour = "black",fill=F,size=1),
        panel.grid.major = element_line(colour = "grey",size=0.25,linetype='longdash'),
        panel.grid.minor = element_blank(),
        axis.title.y=element_text(size=11,colour="grey20"),
        axis.title.x=element_text(size=9,colour="grey20"),
        panel.background = element_rect(fill = NA,colour = "black"))

png_sl


ggplot(png_yr_mth, aes(year_mth, yr_level_mm))+
  #geom_line(size=0.5)+
  geom_point(shape=2,size=1) +
  geom_path(size=1)
