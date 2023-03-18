# -*- coding: utf-8 -*-
"""
Created on Fri Feb 17 09:44:20 2023

@author: Jason
"""
from selenium import webdriver
from selenium.webdriver.support.wait import WebDriverWait    
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException, NoAlertPresentException, StaleElementReferenceException
import pandas as pd
import openpyxl
import time

driver = webdriver.Chrome()
driver.get('https://mspotrace.org.my/Sccs_list')
time.sleep(20)

# Get list of elements
elements = WebDriverWait(driver,20).until(EC.presence_of_all_elements_located((By.XPATH, "//a[@title='View on Map']")))

# Loop through element popups and pull details of facilities into DF
pos = 0
df = pd.DataFrame(columns=['facility_name','other_details','gmaps_url'])
df_out = pd.DataFrame(columns=['facility_name','other_details','gmaps_url'])

for iii in range(1,2):
    for i in range(1,11):
        try: 
            data = []
            #driver.find_element(By.XPATH, f"(//a[@title= 'View on Map'])[{i}]").click()
            element = WebDriverWait(driver, 20).until(EC.visibility_of_element_located((By.XPATH, f"(//a[@title= 'View on Map'])[{i}]")))
            element.click()
            time.sleep(10)
            facility_name = driver.find_element_by_xpath('//h4[@class="modal-title"]').text
            other_details = driver.find_element_by_xpath('//div[@class="modal-body"]').text
            time.sleep(5)
            try:
                gmaps_url = driver.find_element_by_xpath("//a[contains(@href,'https://maps.google.com/maps?ll=')]").get_attribute("href")
                print(gmaps_url)
            except NoSuchElementException:
                gmaps_url = ""  
                time.sleep(1)
            data.append(facility_name)
            data.append(other_details)
            data.append(gmaps_url)
            df.loc[pos] = data
            WebDriverWait(driver,20).until(EC.element_to_be_clickable((By.CSS_SELECTOR, "button[aria-label='Close'] > span"))).click() # close popup window
            print("Scraping info for",facility_name,"")
            time.sleep(5)
            pos+=1

        except Exception:
            alert = driver.switch_to.alert
            print("No geo location information")
            alert.accept()
            pass
        
    # click next
    btnNext = driver.find_element(By.XPATH,'//*[@id="dTable_next"]/a')
    driver.execute_script("arguments[0].scrollIntoView();", btnNext)
    driver.execute_script("arguments[0].click();", btnNext)
    time.sleep(10)
    
    # print current df. You may want to store it and print in the end only?
    df_out = df_out.append(df)
    
    # Get list of elements again
    elements = WebDriverWait(driver, 20).until(EC.presence_of_all_elements_located((By.XPATH, "//a[@title='View on Map']")))

    # Resetting vars again
    pos = 0
    df = pd.DataFrame(columns=['facility_name','other_details','gmaps_url'])

###################
### clean up data 
###################

# details
details_df = df_out.drop(['facility_name','gmaps_url'],axis=1)
details_df['other_details'] = details_df['other_details'].str.split('Organisation').str.get(1)
details_df = details_df['other_details'].astype('str').str.split('\n',expand=True)
details_df.drop([0,5], axis=1, inplace=True) 
details_df[1] = details_df[1].str.split(':').str[1]
details_df[2] = details_df[2].str.split(':').str[1]
details_df[3] = details_df[3].str.split(':').str[1]
details_df[4] = details_df[4].str.split(':').str[1]
details_df = details_df.apply(lambda x: x.str.strip())

# facility
facility_df = df_out.drop(['other_details','gmaps_url'],axis=1)
facility_df['id'] = facility_df['facility_name'].str.extract('\[(.*?)\]')
facility_df['facility_name'] = facility_df['facility_name'].str.split('[').str[0]
facility_df = facility_df.apply(lambda x: x.str.strip())

# coordinates
# def find_between(s, first, last):
#     try:
#         start = s.index(first) + len(first)
#         end = s.index(last, start)
#         return s[start:end]
#     except ValueError:
#         return ""
    

# info = find_between(gmaps_url, "https://maps.google.com/maps?ll=", "&z=12&t=h&hl=en-US&gl=US&mapclient=apiv3")
# lat_long = info.split(',')
# latitude = lat_long[0]
# longitude = lat_long[1]

coords_df = df_out.drop(['other_details','facility_name'],axis=1)
coords_df['coords'] = coords_df['gmaps_url'].str.split('=').str[1]
coords_df['coords'] = coords_df['coords'].str.replace('&z' , '')
coords_df = coords_df['coords'].astype('str').str.split(',',expand=True)
# create a dictionary to map old column names to new column names
new_column_names = {0: 'latitude', 1: 'longitude' }
# rename columns using the dictionary
coords_df = coords_df.rename(columns=new_column_names)

############################
## Merge and export
############################

# merge to get full clean DF
merged_df = pd.concat([facility_df, details_df, coords_df], axis=1)

# create a dictionary to map old column names to new column names
new_column_names = {1: 'mspo_certified', 2: 'address', 3: 'mill_cap', 4: 'mpob_no' }

# rename columns using the dictionary
merged_df = merged_df.rename(columns=new_column_names)

# convert mpob number from no to string
merged_df['mpob_no'] = merged_df['mpob_no'].astype(str) 

# Export to csv
merged_df.to_csv('D:/mspotrace_sccs_data1.csv',index=False,encoding='utf-8')

# Append to csv
merged_df.to_csv('D:/mspotrace_sccs_data.csv', mode='a', index = False, header=None,encoding='utf-8')
