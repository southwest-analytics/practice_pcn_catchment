# 0. Load libraries and define functions ----
# ═══════════════════════════════════════════
library(tidyverse)
library(leaflet)
library(sf)

fnCreateShapefile <- function(sf, df, org_type, org_list = NULL, area_type, catchment_type, min_pct){
  # Error checking
  if(!(catchment_type %in% c('FPTP', 'MINPCT')))
    stop('Catchment type invalid, should be FPTP or MINPCT')
  if(!(org_type %in% c('PRAC', 'PCN')))
    stop('Catchment type invalid, should be PRAC or PCN')
  if(!(area_type %in% c('LSOA11', 'LSOA21', 'MSOA11', 'MSOA21')))
    stop('Area type invalid, should be LSOA11, LSOA21, MSOA11 or MSOA21')
  if(catchment_type == 'MINPCT' & is.na(as.numeric(min_pct)))
    stop('For catchment type MINPCT the parameter min_pct should be a numeric value')
  if(catchment_type == 'MINPCT' & !(as.numeric(min_pct) > 0 & as.numeric(min_pct) <= 1))
    stop('For catchment type MINPCT the parameter min_pct should be greater than 0 and less than or equal to 1')
  
  # Convert to numeric  
  min_pct <- as.numeric(min_pct)
  
  # Filter catchment data to organisation and area type
  df <- df %>% filter(ORG_TYPE == org_type & AREA_TYPE == area_type)

  # Process catchment area type
  if(catchment_type=='FPTP'){
    df <- df %>% 
      mutate(RND = runif(n = NROW(.))) %>%
      arrange(AREA_CODE, desc(PCT), desc(RND)) %>%
      group_by(AREA_CODE) %>%
      slice_head(n = 1) %>%
      ungroup() %>% 
      select(-RND)
  } else {
    df <- df %>% 
      filter(PCT >= min_pct)
  }

  # If the org_list is not empty filter df to selected organisations
  if(!is.null(org_list))
    df <- df %>% filter(ORG_CODE %in% org_list)
  
  link_by <- 'AREA_CODE'
  names(link_by) <- paste0(area_type, 'CD')

  # Link to the shapefile and summarise (dissolve)
  sf <- sf %>% 
    inner_join(df, by = link_by) %>%
    st_make_valid() %>%
    group_by(ORG_CODE) %>%
    summarise() %>%
    ungroup()
  
  # Return the shapefile
  return(sf)
}
  
# 1. File locations ----
# ══════════════════════

# * 1.1. Catchment area data ----
# ───────────────────────────────
catchment_data_robj_file <- './output/practice_pcn_catchment_data.RObj'

# * 1.2. LSOA 2011 shapefile ----
# ───────────────────────────────
lsoa_2011_shp_zip <- './data/LSOA_2011_BGC.zip'
lsoa_2011_shp_dsn <- './data/LSOA_2011'
lsoa_2011_shp_layer <- 'LSOA11'

# * 1.3. LSOA 2021 shapefile ----
# ───────────────────────────────
lsoa_2021_shp_zip <- './data/LSOA_2021_BGC.zip'
lsoa_2021_shp_dsn <- './data/LSOA_2021'
lsoa_2021_shp_layer <- 'LSOA21'

# * 1.4. MSOA 2011 shapefile ----
# ───────────────────────────────
msoa_2011_shp_zip <- './data/MSOA_2011_BGC.zip'
msoa_2011_shp_dsn <- './data/MSOA_2011'
msoa_2011_shp_layer <- 'MSOA11'

# * 1.5. MSOA 2021 shapefile ----
# ───────────────────────────────
msoa_2021_shp_zip <- './data/MSOA_2021_BGC.zip'
msoa_2021_shp_dsn <- './data/MSOA_2021'
msoa_2021_shp_layer <- 'MSOA21'

# 2. Load data ----
# ═════════════════

# * 2.1. Catchment area data ----
# ───────────────────────────────
load(catchment_data_robj_file)

# * 2.2. LSOA 2011 shapefile ----
# ───────────────────────────────
#Extract the files from the zip file
unzip(zipfile = lsoa_2011_shp_zip, exdir = './data/LSOA_2011')

# Read in the shapefile data and filter to English areas only
sf_lsoa11 <- st_read(dsn = lsoa_2011_shp_dsn, layer = lsoa_2011_shp_layer) %>%
  st_transform(crs = 4326) %>%
  filter(grepl('^E', LSOA11CD))

# * 2.3. LSOA 2021 shapefile ----
# ───────────────────────────────
#Extract the files from the zip file
unzip(zipfile = lsoa_2021_shp_zip, exdir = './data/LSOA_2021')

# Read in the shapefile data and filter to English areas only
sf_lsoa21 <- st_read(dsn = lsoa_2021_shp_dsn, layer = lsoa_2021_shp_layer) %>%
  st_transform(crs = 4326) %>%
  filter(grepl('^E', LSOA21CD))

# * 2.4. MSOA 2011 shapefile ----
# ───────────────────────────────
#Extract the files from the zip file
unzip(zipfile = msoa_2011_shp_zip, exdir = './data/MSOA_2011')

# Read in the shapefile data and filter to English areas only
sf_msoa11 <- st_read(dsn = msoa_2011_shp_dsn, layer = msoa_2011_shp_layer) %>%
  st_transform(crs = 4326) %>%
  filter(grepl('^E', MSOA11CD))

# * 2.5. MSOA 2021 shapefile ----
# ───────────────────────────────
#Extract the files from the zip file
unzip(zipfile = msoa_2021_shp_zip, exdir = './data/MSOA_2021')

# Read in the shapefile data and filter to English areas only
sf_msoa21 <- st_read(dsn = msoa_2021_shp_dsn, layer = msoa_2021_shp_layer) %>%
  st_transform(crs = 4326) %>%
  filter(grepl('^E', MSOA21CD))

# 3. Process data ----
# ════════════════════

#catchment_type <- 'MINPCT'
#min_pct <- 0.05
catchment_type <- 'FPTP'

org_list <- df_geocoded_lu %>% filter(PCN_CODE == 'U06387') %>% .$PRAC_CODE
org_type <- 'PRAC'
area_type <- 'LSOA11'

sf_prac <- fnCreateShapefile(sf = sf_lsoa11, 
                             df = df_catchment_data,
                             org_type = org_type,
                             org_list = org_list,
                             area_type = area_type,
                             catchment_type = catchment_type,
                             min_pct = min_pct)

sf_pcn <- fnCreateShapefile(sf = sf_lsoa11, 
                            df = df_catchment_data,
                            org_type = 'PCN',
                            org_list = 'U06387',
                            area_type = area_type,
                            catchment_type = catchment_type,
                            min_pct = min_pct)

palOrg <- colorFactor(palette = 'Set1', c(sf$ORG_CODE, 'U06387'))

leaflet() %>% 
  addTiles() %>%
  addPolygons(data = sf_prac,
              color = ~palOrg(ORG_CODE),
              fillColor = ~palOrg(ORG_CODE),
              popup = ~ORG_CODE,
              group = ~ORG_CODE) %>%
  addPolygons(data = sf_pcn,
              color = palOrg('U06387'),
              fillColor = palOrg('U06387'),
              popup = 'U06387',
              group = 'U06387') %>%
  addLayersControl(overlayGroups = c(org_list, 'U06387'))


