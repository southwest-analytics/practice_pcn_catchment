library(tidyverse)
library(readxl)

# 1. File locations ----
# **********************

# This section needs to be adjusted to point to the correct location for the user

# * 1.1. GP registration data ----
# The GP registration data is in a zipfile and we will use just the 'all' gender file 
gp_registration_zipfile <- './data/gp-reg-pat-prac-lsoa-male-female-Jan-24.zip'
gp_registration_file <- 'gp-reg-pat-prac-lsoa-all.csv'

# * 1.2. Practice, PCN, Sub-ICB, ICB, NHSE Region lookup ----
lookup_file <- './data/gp-reg-pat-prac-map.csv'

# * 1.3. PCN data ----
# The PCN data is in a zipfile and we will use the excel workbook and the PCNDetails worksheet
pcn_zipfile <- './data/ePCN.zip'
pcn_file <- 'ePCN.xlsx'
pcn_sheet <- 'PCNDetails'

# * 1.4. Postcode data ----
# The postcode file is in a zipfile and we will use the ONSPD_MAY_2023_UK.csv file in the Data sub-directory
postcode_zipfile <- './data/ONSPD_NOV_2023_UK.zip'
postcode_file <- 'Data/ONSPD_NOV_2023_UK.csv'

# 2. Read data ----

# * 2.1. GP registration data ----
# Read in the data keeping just the PRACTICE_CODE, LSOA_CODE and NUMBER_OF_PATIENTS fields and filter
# for English LSOAs only (beginning with E)
df_reg_popn <- read.csv(unzip(zipfile = gp_registration_zipfile, files = gp_registration_file)) %>%
  select(3, 5, 7) %>% 
  filter(grepl('^E', LSOA_CODE))

# * 2.2. Lookup data ----
# Read in the data keeping all fields apart from PUBLICATION and EXTRACT_DATE
df_lu <- read.csv(lookup_file) %>% 
  select(-c(1:2))

# * 2.3. PCN data ----
# Read in the PCN data and filter out any entries with a Close Date 
# and keeping just the PCN Code and Postcode fields
df_pcn <- read_excel(path = unzip(zipfile = pcn_zipfile, files = pcn_file),
                   sheet = pcn_sheet) %>% 
  filter(is.na(`Close Date`)) %>%
  select(1, 12)

# * 2.4. Postcode data ----
# Read in the postcode data and keep just the pcds, oa11, lsoa11, 
# oa21, lsoa21, lat and long fields
df_postcode <- read.csv(unzip(zipfile = postcode_zipfile, files = postcode_file)) %>% 
  select(3, 34, 35, 51, 52, 43, 44)

# 3. Process data ----

# * 3.1. Geocode lookup ----

# Join df_lu to df_pcn 
df_lu <- df_lu %>% left_join(df_pcn, by = c('PCN_CODE' = 'PCN Code'))

# Join df_lu to df_postcode for both practice and PCN postcode
df_lu <- df_lu %>% 
  left_join(df_postcode, by = c('PRACTICE_POSTCODE' = 'pcds')) %>%
  left_join(df_postcode, by = c('Postcode' = 'pcds'))

# Reorder and rename the fields
df_lu <- df_lu %>%
  transmute(
    PRAC_CODE = PRACTICE_CODE, PRAC_NAME = PRACTICE_NAME, PRAC_POSTCODE = PRACTICE_POSTCODE,
    PRAC_LAT = lat.x, PRAC_LNG = long.x, 
    PRAC_OA11 = oa11.x, PRAC_LSOA11 = lsoa11.x,
    PRAC_OA21 = oa21.x, PRAC_LSOA21 = lsoa21.x,
    PCN_CODE = PCN_CODE, PCN_NAME = PCN_NAME, PCN_POSTCODE = Postcode,
    PCN_LAT = lat.y, PCN_LNG = long.y,
    PCN_OA11 = oa11.y, PCN_LSOA11 = lsoa11.y,
    PCN_OA21 = oa21.y, PCN_LSOA21 = lsoa21.y,
    ONS_LOC_CODE = ONS_SUB_ICB_LOCATION_CODE, LOC_CODE = SUB_ICB_LOCATION_CODE, LOC_NAME = SUB_ICB_LOCATION_NAME,
    ONS_ICB_CODE, ICB_CODE, ICB_NAME, 
    ONS_NHSER_CODE = ONS_COMM_REGION_CODE, NHSER_CODE = COMM_REGION_CODE, NHSER_NAME = COMM_REGION_NAME,
    SUPPLIER_NAME
  )

# * 3.2. Create catchment areas ----

# * * 3.2.1. Practice catchment area ----
df_prac_catchment <- df_reg_popn %>% 
  left_join(df_reg_popn %>% 
              group_by(LSOA_CODE) %>%
              summarise(TOTAL_REGISTERED_PATIENTS = sum(NUMBER_OF_PATIENTS), .groups = 'keep') %>%
              ungroup(),
            by = 'LSOA_CODE') %>%
  mutate(PCT_REGISTERED_PATIENTS = NUMBER_OF_PATIENTS/TOTAL_REGISTERED_PATIENTS) %>% 
  rename_with(.fn = ~c('PRAC_CODE', 'LSOA11CD', 'REG_POPN', 'TOTAL_REG_POPN', 'PCT'))

# * * 3.2.2. PCN catchment area ----
# Join to PCN and aggregate by PCN
df_pcn_catchment <- df_reg_popn %>% 
  left_join(df_lu %>% select(PRAC_CODE, PCN_CODE), 
            by = c('PRACTICE_CODE' = 'PRAC_CODE')) %>%
  group_by(PCN_CODE, LSOA_CODE) %>%
  summarise(NUMBER_OF_PATIENTS = sum(NUMBER_OF_PATIENTS), .groups = 'keep') %>%
  ungroup()

# Calculate proportion of total registered populatins
df_pcn_catchment <- df_pcn_catchment %>%
  left_join(df_pcn_catchment %>% 
            group_by(LSOA_CODE) %>%
            summarise(TOTAL_REGISTERED_PATIENTS = sum(NUMBER_OF_PATIENTS), .groups = 'keep') %>%
            ungroup(),
          by = 'LSOA_CODE') %>%
  mutate(PCT_REGISTERED_PATIENTS = NUMBER_OF_PATIENTS/TOTAL_REGISTERED_PATIENTS) %>%
  rename_with(.fn = ~c('PCN_CODE', 'LSOA11CD', 'REG_POPN', 'TOTAL_REG_POPN', 'PCT'))

# 4. Write Results ----

save(file = './output/practice_pcn_catchment_data.RObj', list = c('df_prac_catchment', 'df_pcn_catchment', 'df_lu'))

dir.create('./output', showWarnings = FALSE)
write.csv(df_prac_catchment, './output/prac_catchment.csv')
write.csv(df_pcn_catchment, './output/pcn_catchment.csv')
write.csv(df_lu, './output/lookup.csv')



