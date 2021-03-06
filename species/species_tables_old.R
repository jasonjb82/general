# load required libraries -------------------------------------------------
library(pdftools)
library(naniar)
library(tidyverse)
require(dplyr)


# set working directory ---------------------------------------------------
setwd("D:/R/species/")

# extract data using pdftools ---------------------------------------------

# Page 01
pdf_file = "table3_00.pdf"

df <- pdf_text(pdf_file) %>%
    strsplit("\n") %>%
    as_tibble(.name_repair = make.names) %>%
    slice(16:100) %>%
    mutate(
      CDI = str_sub(X,0,9), 
      code = str_sub(X,10,25),
      text = str_sub(X,26,100)) %>%
    # remove original string
    select(-X) %>%
    slice(2:100) %>%
    # remove white spaces around values
    mutate_all(str_trim) %>%
    #filter(!(CDI=="CD")) %>%
    as.data.frame() %>%
    mutate_if(is.character, list(~na_if(.,""))) %>%
    fill(CDI,code) %>%
    mutate(page = pdf_file) %>%
    replace(is.na(.), "") %>%
    mutate(CDI = ifelse(is.na(CDI),0,CDI))

# Page 27
pdf_file = "table3 - 0021.pdf"

df1 <- pdf_text(pdf_file) %>%
  strsplit("\n") %>%
  as_tibble(.name_repair = make.names) %>%
  slice(3:11) %>%
  mutate(
    CDI = str_sub(X,0,9), 
    code = str_sub(X,10,25),
    text = str_sub(X,26,100)) %>%
  # remove original string
  select(-X) %>%
  slice(2:100) %>%
  # remove white spaces around values
  mutate_all(str_trim) %>%
  #filter(!(CDI=="CD")) %>%
  as.data.frame() %>%
  mutate_if(is.character, list(~na_if(.,""))) %>%
  fill(CDI,code) %>%
  mutate(page = pdf_file) %>%
  replace(is.na(.), "") %>%
  mutate(CDI = ifelse(is.na(CDI),0,CDI))


# rest of the pages

## Loop through files and create combined dataframe
filenames <- list.files(pattern="table3 - .*pdf")

combined_df <- data.frame(CDI=character(),
                          dode=character(),
                          text=character())

for (fname in filenames) {
  pdf_file = fname
  
# Page 02 - onwards
data <- pdf_text(pdf_file) %>%
  strsplit("\n") %>%
  as_tibble(.name_repair = make.names) %>%
  slice(3:100) %>%
  mutate(
    CDI = str_sub(X,0,8), 
    code = str_sub(X,14,19),
    text = str_sub(X,20,100),
    page = pdf_file,
    text = str_replace(text, "I ",""),
    code = str_replace(code," ","")) %>%
  # remove original string
  select(-X) %>%
  slice(2:100) %>%
  # remove white spaces around values
  mutate_all(str_trim) %>%
  #filter(!(CDI=="CD")) %>%
  as.data.frame() %>%
  mutate_if(is.character, list(~na_if(.,""))) %>%
  mutate(CDI = ifelse(!is.na(code) & is.na(CDI),"",CDI)) %>%
  mutate(code = str_pad(code,4, side = 'right', pad = 'I')) %>%
  fill(CDI,code) 

  combined_df <- rbind(combined_df,data)
}

merge_df <- rbind(combined_df,df,df1)

# clean up table ----------------------------------------------------------
comb_df <- merge_df %>%
  group_by(CDI,code) %>% 
  select(-page) %>%
  mutate(text = str_replace(text,'[*]','')) %>%
  mutate(text = str_replace(text,'[.]','')) %>%
  summarise_all(funs(paste(., collapse = " ; "))) %>%
  separate(text, c("name", "common_name","common_name1","common_name2","common_name3"), " ; ") %>%
  mutate(common_name = ifelse(!is.na(common_name1),paste0(common_name," ",common_name1),common_name)) %>%
  mutate(common_name = ifelse(!is.na(common_name2),paste0(common_name," ",common_name1," ",common_name2),common_name)) %>%
  mutate(common_name = ifelse(!is.na(common_name2),paste0(common_name," ",common_name1," ",common_name2," ",common_name3),common_name)) %>%
  select(-common_name1,-common_name2,-common_name3) %>%
  #mutate(Genus = stri_extract_first(Name, regex="\\w+")) %>%
  separate(name, into = c("genus", "species","authority"), sep = "\\s",extra="merge") %>%
  mutate(genus = ifelse(grepl('SP$',code),paste0(genus," ",species),genus),
         species = ifelse(grepl('SP$',code),NA,species)) %>%
  mutate(species = ifelse(grepl('^L.',authority),paste0(species," ",authority),species),
         authority = ifelse(grepl('^L.',authority),NA,authority)) %>%
  mutate(authority = str_replace(authority,"[']",'')) %>%
  mutate(genus = ifelse(code == "MIXI",paste0(genus," ",species),genus)) %>%
  mutate(species = ifelse(code == "MIXI",NA,species)) %>%
  mutate(genus = ifelse(code == "CONI",paste0(genus," ",species),genus)) %>%
  mutate(species = ifelse(code == "CONI",NA,species)) %>%
  mutate(common_name = str_squish(common_name))
  #separate(common_name,into = c("authority2","common_name_add"), sep = "(?<=\\))",convert = TRUE, remove=FALSE,fill="right") %>%
  #mutate(authority = ifelse(!is.na(common_name_add),paste0(authority," ",authority2),authority))

         