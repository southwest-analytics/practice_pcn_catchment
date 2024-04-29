# Practice and Primary Care Network (PCN) Catchment Calculation

#### Author: Richard Blackwell
#### Email: richard.blackwell@swahsn.com
#### Date: 2024-04-29

----

## Acknowledgements

<strong>Contains information from NHS England, licensed under the current version of the Open Government Licence</strong>

<strong>Source: Office for National Statistics licensed under the Open Government Licence v.3.0</strong>

----

## Input Data

----

### GP registration data

Source: [NHS Digital](https://digital.nhs.uk/)

Landing Page: [Patients Registered at a GP Practice](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice)

Example Data: [April 2024 data](https://files.digital.nhs.uk/5C/704155/gp-reg-pat-prac-lsoa-male-female-Apr-24.zip)

Notes: Data consists of the number of patients registered at each practice by lower-layer super output area (LSOA) 2011

### Practice, PCN, Sub-ICB, ICB, NHSE Region lookup data

Source: [NHS Digital](https://digital.nhs.uk/)

Landing Page: [Patients Registered at a GP Practice](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice)

Example Data: [April 2024 data](https://files.digital.nhs.uk/31/A5EE4A/gp-reg-pat-prac-map.zip)

Notes: Data consists of the a mapping of practice to parent PCN, to parent sub-ICB (prev. CCG), to parent ICB, to parent NSH England region

### PCN data

Source: [NHS Digital](https://digital.nhs.uk/)

Landing Page: [GP and GP practice related data](https://digital.nhs.uk/services/organisation-data-service/export-data-files/csv-downloads/gp-and-gp-practice-related-data)

Example Data: [April 2024 data](https://digital.nhs.uk/binaries/content/assets/website-assets/services/ods/data-downloads-other-nhs-organisations/epcn.zip)

Notes: Data contains the postcode of the lead practice for each PCN for geocoding

### Postcode data

Source: [Office for National Statistics](https://geoportal.statistics.gov.uk/)

Landing Page: [ONS Postcode Directory](https://geoportal.statistics.gov.uk/search?q=PRD_ONSPD%20FEB_2024&sort=Date%20Created%7Ccreated%7Cdesc)

Example Data: [April 2024 data](https://www.arcgis.com/sharing/rest/content/items/e14b1475ecf74b58804cf667b6740706/data)

Notes: Data contains the latitude and longitude of postcode centroid for geocoding along with the corresponding output area (OA) and lower-layer super output area (LSOA) for 2011 and 2021 mapping.

### OA to LSOA to MSOA Lookup data

Source: [Office for National Statistics](https://geoportal.statistics.gov.uk/)

Landing Page: [ONS Census Lookups Directory](https://geoportal.statistics.gov.uk/search?q=LUP_OA&sort=Date%20Created%7Ccreated%7Cdesc)

Example Data: [2011 data](https://geoportal.statistics.gov.uk/datasets/d382604321554ed49cc15dbc1edb3de3_0/explore)

Example Data: [2021 data](https://geoportal.statistics.gov.uk/datasets/b9ca90c10aaa4b8d9791e9859a38ca67_0/explore)

Notes: Data contains the lookup between output area (OA) and lower-layer super output area (LSOA) and middle-layer super output area (MSOA) for 2011 and 2021 areas.

### LSOA11 to LSOA21 Lookup data

Source: [Office for National Statistics](https://geoportal.statistics.gov.uk/)

Landing Page: [ONS Census Best-fit Lookups Directory](https://geoportal.statistics.gov.uk/search?q=LUP_LSOA_2021_LAD&sort=Date%20Created%7Ccreated%7Cdesc)

Example Data: [2011 to 2021](https://geoportal.statistics.gov.uk/datasets/e99a92fb7607495689f2eeeab8108fd6_0/explore)

Notes: Data contains the lookup between lower-layer super output area (LSOA) 2011 to 2021.

----

## Methodology

### Catchment area data

The `gp-reg-pat-prac-lsoa-all.csv` file is extracted from the GP registration data zip file and the data consists of the following fields

 - `PUBLICATION` - the name of the publication (**GP_PRAC_PAT_LIST**)
 - `EXTRACT_DATE` -  the extract date
 - `PRACTICE_CODE` - the GP practice code
 - `PRACTICE_NAME` - the GP practice name
 - `LSOA_CODE` - the lower-layer super output area (LSOA) 2011 code
 - `SEX` - the gender of the patient (**ALL**)
 - `NUMBER_OF_PATIENTS` - the number of registered patients

The data is filtered by entries that have an `LSOA_CODE` that begins with **E** signifying an English LSOA (excluding patients from unknown LSOAs and also those residing in Wales) and only the `PRACTICE_CODE`, `LSOA_CODE` and `NUMBER_OF_PATIENTS` fields are used.

The `LSOA_(2011)_to_LSOA_(2021)_to_Local_Authority_District_(2022)_Lookup_for_England_and_Wales_(Version_2).csv` lookup file is then used to add in the LSOA 2021 code and the factor that will used to transform the 2011 LSOA population into a 2021 LSOA population. In this situtation this factor is only relevant for those 2011 LSOAs that have been split into a number of new 2021 LSOAs and the factor is 1/N where N is the number of new 2011 LSOAs, for example if a 2011 LSOA was split into 4 new 2021 LSOAs the factor would be 1/4 and would multiply the 2011 LSOA population by the factor 0.25 to obtain the new 2021 LSOA population.

The files `Output_Area_to_Lower_layer_Super_Output_Area_to_Middle_layer_Super_Output_Area_to_Local_Authority_District_(December_2011)_Lookup_in_England_and_Wales.csv` and `Output_Area_to_Lower_layer_Super_Output_Area_to_Middle_layer_Super_Output_Area_to_Local_Authority_District_(December_2021)_Lookup_in_England_and_Wales_v3.csv` are used to add the corresponding MSOAs (2011 and 2021).

The file `gp-reg-pat-prac-map.csv` is then used to add the Primary Care Network (PCN) code corresponding to the practiceto the data. The data is then standardised and pivoted longer to form a data frame consisting of 

 - `ORG_CODE` - practice or PCN code
 - `ORG_TYPE` - 'PRAC' or 'PCN'
 - `AREA_CODE` - LSOA or MSOA code (2011 or 2021)
 - `AREA_TYPE` - 'LSOA11', 'LSOA21', 'MSOA11' or 'MSOA21'
 - `REG_POPN` - registered population

The `PCT` is calculated as the `REG_POPN` divided by the `TOTAL_POPN` which is the sum of the `REG_POPN` for that `AREA_CODE`

### Geocoding data

The lookup data is read from the `gp-reg-pat-prac-map.csv` which consists of the following fields

 - `PUBLICATION` - the name of the publication (**GP_PRAC_PAT_LIST**)
 - `EXTRACT_DATE` - the extract date
 - `PRACTICE_CODE` - the GP practice
 - `PRACTICE_NAME` - the GP practice name
 - `PRACTICE_POSTCODE` - the postcode of the GP practice
 - `PCN_CODE` - the Primary Care Network (PCN) code
 - `PCN_NAME` - the Primary Care Network (PCN) name 
 - `ONS_SUB_ICB_LOCATION_CODE` - the ONS code of the sub-ICB location (previously CCG)
 - `SUB_ICB_LOCATION_CODE` - the NHS code of the sub-ICB location (previously CCG)
 - `SUB_ICB_LOCATION_NAME` - the name of the sub-ICB location (previously CCG)
 - `ONS_ICB_CODE` - the ONS code of the ICB
 - `ICB_CODE` - the NHS code of the ICB
 - `ICB_NAME` - the name of the ICB
 - `ONS_COMM_REGION_CODE` - the ONS code of the NHS England region
 - `COMM_REGION_CODE` - the NHS code of the NHS England region
 - `COMM_REGION_NAME` - the name of the NHS England region
 - `SUPPLIER_NAME` - the GP IT system provider

The PCN data excel workbook is extracted from the PCN data zip file and the `PCNDetails` worksheet is read in as a data set and this data consists of the following fields

 - `PCN Code`
 - `PCN Name`
 - `Current Sub ICB Loc Code`
 - `Sub ICB Location`
 - `Open Date`
 - `Close Date`
 - `Address Line 1`
 - `Address Line 2`
 - `Address Line 3`
 - `Address Line 4`
 - `Address Line 5`
 - `Postcode`

We will filter the data by entire that have an **NA** `Close Date` to ensure they are active PCNs and we will select the `PCN Code` and `Postcode` from this data set and join it to the lookup data in order to have a postcode for the PCN as well as a postcode for the practice.

We will then extract the `./data/ONSPD_MAY_2023_UK.csv` file from the postcode zip file and keep just the following fields

 - `pcds` - standard format postcode (2-4 digit outward code with 3 digit inward code separated by a single space)
 - `oa11` - output area code (2011)
 - `lsoa11` - lower-layer super output area code (2011)
 - `oa21` - output area code (2021)
 - `lsoa21` - lower-layer super output area code (2021)
 - `lat` - degrees latitude to 6 decimal places
 - `long` - degrees longitude to 6 decimal places

This is then joined to the mapping data by the practice postcode and the PCN postcode.

----

## Output

The output consists of 3 data frames

### Catchment data

The data frame name is `df_catchment_data` and this provides the proportion of each `AREA_CODE`'s registered population by `ORG_CODE` and the fields are as follows

 - `ORG_CODE` - organisation code (practice or PCN)
 - `ORG_TYPE` - organisation type ('PRAC' or 'PCN')
 - `AREA_CODE` - census area
 - `AREA_TYPE` - census area type ('LSOA11', 'LSOA21', 'MSOA11' or 'MSOA21')
 - `REG_POPN` - registered population
 - `TOTAL_REG_POPN` - total registered population for census area
 - `PCT` - registered population as proportion of total registered population

### LSOA 2011 to LSOA 2021 Lookup

The data frame name is `df_lsoa11_lsoa21_lu` and this provides the mapping between 2011 and 2021 LSOAs and the factor that should be used to convert the population from 2011 to 2021  `FCT_11_21` or to convert the population from 2021 to 2011 `FCT_21_11` and the fields are as follows

 - `LSOA11CD` - LSOA 2011 code
 - `LSOA21CD` - LSOA 2021 code
 - `CHGIND` - Change indicator from 2011 to 2021 LSOAs (U - unchanged, S - split, M - Merged, X - complex)
 - `FCT_11_21` - factor used to convert population from 2011 to 2021 areas
 - `FCT_21_11` - factor used to convert population from 2021 to 2011 areas

### Geocoded Lookup

The data frame name is `df_geocoded_lu` and this provides the lookup data for each practice and 

 - `PRAC_CODE` - the GP practice code
 - `PRAC_NAME` - the GP practice name
 - `PRAC_POSTCODE` - the postcode of the GP practice
 - `PRAC_LAT` - the degrees latitude of the GP practice
 - `PRAC_LNG` - the degrees longitude of the GP practice
 - `PRAC_OA11` - the output area (OA) 2011 of the GP practice
 - `PRAC_LSOA11` - the lower-layer super output area (LSOA) 2011 of the GP practice
 - `PRAC_OA21` - the output area (OA) 2021 of the GP practice
 - `PRAC_LSOA21` - the lower-layer super output area (LSOA) 2021 of the GP practice
 - `PCN_CODE` - the PCN code
 - `PCN_NAME` - the PCN name
 - `PCN_POSTCODE` - the postcode of the PCN
 - `PCN_LAT` - the degrees latitude of the PCN
 - `PCN_LNG` - the degrees longitude of the PCN
 - `PCN_OA11` - the output area (OA) 2011 of the PCN
 - `PCN_LSOA11` - the lower-layer super output area (LSOA) 2011 of the PCN
 - `PCN_OA21` - the output area (OA) 2021 of the PCN
 - `PCN_LSOA21` - the lower-layer super output area (LSOA) 2021 of the PCN
 - `ONS_LOC_CODE` - the ONS code of the sub-ICB location (previously CCG)
 - `LOC_CODE` - the NHS code of the sub-ICB location (previously CCG)
 - `LOC_NAME` - the name of the sub-ICB location (previously CCG)
 - `ONS_ICB_CODE` - the ONS code of the ICB
 - `ICB_CODE` - the NHS code of the ICB
 - `ICB_NAME` - the name of the ICB
 - `ONS_NHSER_CODE` - the ONS code of the NHS England region
 - `NHSER_CODE` - the NHS code of the NHS England region
 - `NHSER_NAME` - the name of the NHS England region
 - `SUPPLIER_NAME` - the GP IT system provider

