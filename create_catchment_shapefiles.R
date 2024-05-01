# 0. Load libraries and define functions ----
# ═══════════════════════════════════════════
library(tidyverse)
library(sf)

fnCreateShapefile <- function(sf, df, org_type, org_list = NULL, area_type, catchment_type, min_pct = 0.05){
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
