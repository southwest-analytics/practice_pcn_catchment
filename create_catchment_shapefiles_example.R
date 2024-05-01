# 0. Load source ----
# ═══════════════════
source('create_catchment_shapefiles.R')

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
                             catchment_type = catchment_type)
                             #min_pct = 0.05)

sf_pcn <- fnCreateShapefile(sf = sf_lsoa11, 
                            df = df_catchment_data,
                            org_type = 'PCN',
                            org_list = 'U06387',
                            area_type = area_type,
                            catchment_type = catchment_type)
                            #min_pct = NULL)

palOrg <- colorFactor(palette = 'Set1', c(sf_prac$ORG_CODE, 'U06387'))

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


