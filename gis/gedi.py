# -*- coding: utf-8 -*-
"""
Created on Fri Apr 17 19:09:57 2020

@author: Jason
"""

from pyGEDI import *
import numpy as np

username='jasonjb82'
password='Rigel1853'

session=sessionNASA(username,password)

data_dir = 'D:/GIS/GEDI/kenyir/'

   
ul_lat= 4.946206
lr_lat= 4.890762
ul_lon= 102.619699  
lr_lon= 102.685380 
bbox=[ul_lat,ul_lon,lr_lat,lr_lon]

roduct_1B='GEDI01_B'
product_2A='GEDI02_A'
product_2B='GEDI02_B'

version='001'

outdir_2A= data_dir +product_2A+'.'+version+'/'
gediDownload(outdir_2A,product_2A,version,bbox,session)

fileh5_2A=data_dir +'GEDI02_A.001/2019.06.26/GEDI02_A_2019177193553_O03043_T02011_02_001_01.h5'
h5_2A=getH5(fileh5_2A)

getLayer('',[h5_2A])

idsbox=idsBox(h5_2A,'lat_lowestmode','lon_lowestmode',bbox)

layers=['shot_number','lat_lowestmode','lon_lowestmode', 'sensitivity','quality_flag','rh']
dfbox=generateBoxDataFrame([h5_2A],layers,idsbox)
dfbox.head()

dfbox['max_rh'] = [np.max(i) for i in dfbox['rh']]
dfbox.head()

df2csv(dfbox,filename='Box_GEDI02_A',outdir=data_dir)

csv2shp(data_dir + 'Box_GEDI02_A.csv',filename='Box_GEDI02_A',outdir=data_dir)

shp2tiff(data_dir + 'Box_GEDI02_A.shp', layername='max_rh', 
        pixelsize='0.00025', 
        nodata='225', 
        ot='float',
        filename='Box_GEDI02_A',
        outdir=data_dir)


import geopandas as gpd
from mpl_toolkits.mplot3d import Axes3D
import plotly.express as px
import folium


GEDI_shp = gpd.read_file(data_dir + 'Box_GEDI02_A.shp')
plotSHP(GEDI_shp,'rh',colormap='Spectral_r')
GEDI_shp.head()

