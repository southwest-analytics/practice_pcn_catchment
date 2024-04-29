# 0. Load libraries and define functions ----
# ═══════════════════════════════════════════
library(tidyverse)
library(readxl)
library(sf)

# Start timer
dt_start <- Sys.time()

# Set the minimum percentage for the MinPCT method of assignment
minimum_pct <- 0.05

# Function to create the catchment data for organisation and area
fnCreateCatchmentData <- function(df, org_type, area_type){
  # df should consist of ORG_CODE, AREA_CODE, and REG_POPN
  df <- df %>% 
    mutate(ORG_CODE, ORG_TYPE = org_type, 
           AREA_CODE, AREA_TYPE = area_type, 
           REG_POPN,
           .keep = 'none') %>%
    # Group and summarise
    group_by(ORG_CODE, ORG_TYPE, AREA_CODE, AREA_TYPE) %>%
    summarise(REG_POPN = sum(REG_POPN, na.rm = TRUE), .groups = 'keep') %>%
    ungroup() %>%
    left_join(
      df %>% 
        group_by(AREA_CODE) %>%
        summarise(TOTAL_POPN = sum(REG_POPN, na.rm = TRUE)) %>%
        ungroup(),
      by = 'AREA_CODE'
    ) %>%
    mutate(PCT = REG_POPN / TOTAL_POPN)
  return(df)
}

# 1. File locations ----
# ══════════════════════
# This section needs to be adjusted to point to the correct location for the user

# * 1.1. GP registration data ----
# ────────────────────────────────
# The GP registration data is in a zipfile and we will use just the 'all' gender file 
gp_registration_zipfile <- './data/gp-reg-pat-prac-lsoa-male-female_20240411.zip'
gp_registration_file <- 'gp-reg-pat-prac-lsoa-all.csv'

# * 1.2. Practice, PCN, Sub-ICB, ICB, NHSE Region lookup ----
# ───────────────────────────────────────────────────────────
lookup_zipfile <- './data/gp-reg-pat-prac-map_20240411.zip'
lookup_file <- 'gp-reg-pat-prac-map.csv'

# * 1.3. PCN data ----
# ────────────────────
# The PCN data is in a zipfile and we will use the excel workbook and the PCNDetails worksheet
pcn_zipfile <- './data/ePCN_20240326.zip'
pcn_file <- 'ePCN.xlsx'
pcn_sheet <- 'PCNDetails'

# * 1.4. Postcode data ----
# ─────────────────────────
# The postcode file is in a zipfile and we will use the ONSPD_MAY_2023_UK.csv file in the Data sub-directory
postcode_zipfile <- './data/ONSPD_FEB_2024_UK_20240218.zip'
postcode_file <- 'Data/ONSPD_FEB_2024_UK.csv'

# * 1.5. LSOA 2011 to LSOA 2021 lookup data ----
# ──────────────────────────────────────────────
lsoa11_lsoa21_lu_file <- './data/LSOA_(2011)_to_LSOA_(2021)_to_Local_Authority_District_(2022)_Lookup_for_England_and_Wales_(Version_2).csv'

# * 1.6. OA to LSOA to MSOA lookup data ----
# ──────────────────────────────────────────
# * * 1.6.1 LSOA to MSOA 2011 ----
oa11_lsoa11_msoa11_lu_file <- './data/Output_Area_to_Lower_layer_Super_Output_Area_to_Middle_layer_Super_Output_Area_to_Local_Authority_District_(December_2011)_Lookup_in_England_and_Wales.csv'

# * * 1.6.2 LSOA to MSOA 2021 ----
oa21_lsoa21_msoa21_lu_file <- './data/Output_Area_to_Lower_layer_Super_Output_Area_to_Middle_layer_Super_Output_Area_to_Local_Authority_District_(December_2021)_Lookup_in_England_and_Wales_v3.csv'

# 2. Read data ----
# ═════════════════

# * 2.1. GP registration data ----
# ────────────────────────────────
# Read in the data keeping just the PRACTICE_CODE, LSOA_CODE and NUMBER_OF_PATIENTS fields and filter
# for English LSOAs only (beginning with E)
df_reg_popn <- read.csv(unzip(zipfile = gp_registration_zipfile, files = gp_registration_file, exdir = './data')) %>%
  select(3, 5, 7) %>% 
  filter(grepl('^E', LSOA_CODE)) %>%
  mutate(PRAC_CODE = PRACTICE_CODE,
         LSOA11CD = LSOA_CODE,
         REG_POPN_LSOA11 = NUMBER_OF_PATIENTS,
         .keep = 'none')

# * 2.2. Lookup data ----
# ───────────────────────
# Read in the data keeping all fields apart from PUBLICATION and EXTRACT_DATE
df_geocoded_lu <- read.csv(unzip(zipfile = lookup_zipfile, files = lookup_file, exdir = './data')) %>% 
  select(-c(1:2))

# * 2.3. PCN data ----
# ────────────────────
# Read in the PCN data and filter out any entries with a Close Date 
# and keeping just the PCN Code and Postcode fields
df_pcn <- read_excel(path = unzip(zipfile = pcn_zipfile, files = pcn_file, exdir = './data'),
                   sheet = pcn_sheet) %>% 
  filter(is.na(`Close Date`)) %>%
  select(1, 12)

# * 2.4. Postcode data ----
# ─────────────────────────
# Read in the postcode data and keep just the pcds, oa11, lsoa11, msoa11, 
# oa21, lsoa21, msoa21, lat and long fields
df_postcode <- read.csv(unzip(zipfile = postcode_zipfile, files = postcode_file, exdir = './data')) %>% 
  select(3, 34, 35, 36, 51, 52, 53, 43, 44)

# * 2.5. LSOA 2011 to LSOA 2021 lookup data ----
# ──────────────────────────────────────────────
df_lsoa11_lsoa21_lu <- read.csv(lsoa11_lsoa21_lu_file) %>% 
  select(LSOA11CD, LSOA21CD, CHGIND) %>%
    # Delete the following X (complex) changes as they are very small 
    # overlaps that can be ignored
    filter(
      !(
        CHGIND == 'X' & 
        (
          (LSOA11CD == 'E01027506' & LSOA21CD == 'E01035624') |
          (LSOA11CD == 'E01008187' & LSOA21CD == 'E01035637') |
          (LSOA11CD == 'E01023964' & LSOA21CD == 'E01035581') |
          (LSOA11CD == 'E01023508' & LSOA21CD == 'E01035582')
        )
      )
    )

# Calculate the factor that we will multiply the population by to
# convert from 2011 into 2021 or vice versa
df_lsoa11_lsoa21_lu <- df_lsoa11_lsoa21_lu %>% 
  left_join(
    df_lsoa11_lsoa21_lu %>% 
      group_by(LSOA11CD) %>%
      summarise(FCT_11_21 = 1/n()) %>%
      ungroup(),
    by = 'LSOA11CD'
  ) %>%
  left_join(
    df_lsoa11_lsoa21_lu %>% 
      group_by(LSOA21CD) %>%
      summarise(FCT_21_11 = 1/n()) %>%
      ungroup(),
    by = 'LSOA21CD'
  )

# * 2.6. OA to LSOA to MSOA lookup data ----
# ────────────────────────────────────

# * * 2.6.1. OA11 to LSOA11 to MSOA11
df_oa11_lsoa11_msoa11_lu <- read.csv(oa11_lsoa11_msoa11_lu_file) %>% 
  select(OA11CD, LSOA11CD, MSOA11CD)

# * * 2.6.2. OA21 to LSOA21 to MSOA21
df_oa21_lsoa21_msoa21_lu <- read.csv(oa21_lsoa21_msoa21_lu_file) %>% 
  select(OA21CD, LSOA21CD, MSOA21CD)

# 3. Process data ----
# ════════════════════

# * 3.1. Geocode lookup ----
# ──────────────────────────

# Join df_lu to df_pcn 
df_geocoded_lu <- df_geocoded_lu %>% left_join(df_pcn, by = c('PCN_CODE' = 'PCN Code'))

# Join df_lu to df_postcode for both practice and PCN postcode
df_geocoded_lu <- df_geocoded_lu %>% 
  left_join(df_postcode, by = c('PRACTICE_POSTCODE' = 'pcds')) %>%
  left_join(df_postcode, by = c('Postcode' = 'pcds'))

# Reorder and rename the fields
df_geocoded_lu <- df_geocoded_lu %>%
  transmute(
    PRAC_CODE = PRACTICE_CODE, PRAC_NAME = PRACTICE_NAME, PRAC_POSTCODE = PRACTICE_POSTCODE,
    PRAC_LAT = lat.x, PRAC_LNG = long.x, 
    PRAC_OA11 = oa11.x, PRAC_LSOA11 = lsoa11.x, PRAC_MSOA11 = lsoa11.x,
    PRAC_OA21 = oa21.x, PRAC_LSOA21 = lsoa21.x, PRAC_MSOA21 = msoa21.x,
    PCN_CODE = PCN_CODE, PCN_NAME = PCN_NAME, PCN_POSTCODE = Postcode,
    PCN_LAT = lat.y, PCN_LNG = long.y,
    PCN_OA11 = oa11.y, PCN_LSOA11 = lsoa11.y, PCN_MSOA11 = msoa11.y,
    PCN_OA21 = oa21.y, PCN_LSOA21 = lsoa21.y, PCN_MSOA21 = msoa21.y,
    ONS_LOC_CODE = ONS_SUB_ICB_LOCATION_CODE, LOC_CODE = SUB_ICB_LOCATION_CODE, LOC_NAME = SUB_ICB_LOCATION_NAME,
    ONS_ICB_CODE, ICB_CODE, ICB_NAME, 
    ONS_NHSER_CODE = ONS_COMM_REGION_CODE, NHSER_CODE = COMM_REGION_CODE, NHSER_NAME = COMM_REGION_NAME,
    SUPPLIER_NAME
  )

# * 3.2. Create catchment area data ----
# ──────────────────────────────────────

df_reg_popn <- df_reg_popn %>% 
  # Apply the factor to convert from 2011 to 2021 LSOAs
  left_join(
    df_lsoa11_lsoa21_lu,
    by = 'LSOA11CD',
    relationship = 'many-to-many') %>% 
  mutate(REG_POPN_LSOA21 = REG_POPN_LSOA11 * FCT_11_21) %>%
  # Add in MSOA 2011
  left_join(df_oa11_lsoa11_msoa11_lu %>% distinct(LSOA11CD, MSOA11CD),
            by = 'LSOA11CD') %>%
  # Add in MSOA 2021
  left_join(df_oa21_lsoa21_msoa21_lu %>% distinct(LSOA21CD, MSOA21CD),
            by = 'LSOA21CD') %>%
  # Add in PCN
  left_join(df_geocoded_lu %>% distinct(PRAC_CODE, PCN_CODE),
            by = 'PRAC_CODE') %>%
  # Select only the relevant fields
  select(1, 11, 2, 9, 4, 10, 3, 8)

# * * 3.2.1. Practice and LSOA ----
df_catchment_data <- fnCreateCatchmentData(
  df = df_reg_popn %>% 
    mutate(ORG_CODE = PRAC_CODE, 
           AREA_CODE = LSOA11CD, 
           REG_POPN = REG_POPN_LSOA11,
           .keep = 'none'),
  org_type = 'PRAC',
  area_type = 'LSOA11')

# Practice and LSOA 2021
df_catchment_data <- df_catchment_data %>%
  bind_rows(
    fnCreateCatchmentData(
      df = df_reg_popn %>% 
        mutate(ORG_CODE = PRAC_CODE, 
        AREA_CODE = LSOA21CD, 
        REG_POPN = REG_POPN_LSOA21,
        .keep = 'none'),
      org_type = 'PRAC',
      area_type = 'LSOA21'))

# * * 3.2.2. Practice and MSOA ----
# Practice and MSOA 2011
df_catchment_data <- df_catchment_data %>%
  bind_rows(
    fnCreateCatchmentData(
      df = df_reg_popn %>% 
        mutate(ORG_CODE = PRAC_CODE, 
               AREA_CODE = MSOA11CD, 
               REG_POPN = REG_POPN_LSOA11,
               .keep = 'none'),
      org_type = 'PRAC',
      area_type = 'MSOA11'))

# Practice and MSOA 2021
df_catchment_data <- df_catchment_data %>%
  bind_rows(
    fnCreateCatchmentData(
      df = df_reg_popn %>% 
        mutate(ORG_CODE = PRAC_CODE, 
        AREA_CODE = MSOA21CD, 
        REG_POPN = REG_POPN_LSOA21,
        .keep = 'none'),
      org_type = 'PRAC',
      area_type = 'MSOA21'))

# * * 3.2.3. PCN and LSOA ----
# PCN and LSOA 2011
df_catchment_data <- df_catchment_data %>%
  bind_rows(
    fnCreateCatchmentData(
      df = df_reg_popn %>% 
        mutate(ORG_CODE = PCN_CODE, 
               AREA_CODE = LSOA11CD, 
               REG_POPN = REG_POPN_LSOA11,
               .keep = 'none'),
      org_type = 'PCN',
      area_type = 'LSOA11'))

# PCN and LSOA 2021
df_catchment_data <- df_catchment_data %>%
  bind_rows(
    fnCreateCatchmentData(
      df = df_reg_popn %>% 
        mutate(ORG_CODE = PCN_CODE, 
               AREA_CODE = LSOA21CD, 
               REG_POPN = REG_POPN_LSOA21,
               .keep = 'none'),
      org_type = 'PCN',
      area_type = 'LSOA21'))

# * * 3.2.4. PCN and MSOA ----
# PCN and MSOA 2011
df_catchment_data <- df_catchment_data %>%
  bind_rows(
    fnCreateCatchmentData(
      df = df_reg_popn %>% 
        mutate(ORG_CODE = PCN_CODE, 
               AREA_CODE = MSOA11CD, 
               REG_POPN = REG_POPN_LSOA11,
               .keep = 'none'),
      org_type = 'PCN',
      area_type = 'MSOA11'))

# PCN and MSOA 2021
df_catchment_data <- df_catchment_data %>%
  bind_rows(
    fnCreateCatchmentData(
      df = df_reg_popn %>% 
        mutate(ORG_CODE = PCN_CODE, 
               AREA_CODE = MSOA21CD, 
               REG_POPN = REG_POPN_LSOA21,
               .keep = 'none'),
      org_type = 'PCN',
      area_type = 'MSOA21'))

# 4. Write Results ----
# ═════════════════════

# Create the output
dir.create('./output', showWarnings = FALSE)

# * 4.1. Save the RObj and lookup file to the output folder ----
# ──────────────────────────────────────────────────────────────
save(file = './output/practice_pcn_catchment_data.RObj', 
     list = c('df_geocoded_lu', 'df_lsoa11_lsoa21_lu', 'df_catchment_data'))
write.csv(df_geocoded_lu, './output/geocoded_organisation_lookup.csv')
write.csv(df_lsoa11_lsoa21_lu, './output/lsoa11_lsoa21_lookup.csv')

# End timer
Sys.time() - dt_start
