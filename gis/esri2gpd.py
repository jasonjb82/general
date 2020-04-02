# -*- coding: utf-8 -*-
"""
Created on Wed Apr  1 16:56:41 2020

@author: Jason
"""

import esri2gpd

fields= ['kode_prov,fungsi,fungsi_kws,sk_kawasan,lindung']

url = "https://gis.wwf.id/server/rest/services/National/Kawasan_Hutan_Indonesia_KLHK_2014/FeatureServer/0"
gdf = esri2gpd.get(url, fields=fields, where="kode_prov='92'")

gdf.head()

gdf.to_file("D:/z_Temp/klhk/kh_2014/kh_prov15.shp")
