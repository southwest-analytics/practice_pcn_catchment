# Practice and Primary Care Network (PCN) Catchment Calculation

#### Author: Richard Blackwell
#### Email: richard.blackwell@swahsn.com
#### Date: 2023-08-15

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

Example Data: [July 2023 data](https://files.digital.nhs.uk/E3/7F080B/gp-reg-pat-prac-lsoa-male-female-July-23.zip)

Notes: Data consists of the number of patients registered at each practice by lower-layer super output area (LSOA) 2011

### Practice, PCN, Sub-ICB, ICB, NHSE Region lookup data

Source: [NHS Digital](https://digital.nhs.uk/)

Landing Page: [Patients Registered at a GP Practice](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice)

Example Data: [July 2023 data](https://files.digital.nhs.uk/2C/59030E/gp-reg-pat-prac-map.csv)

Notes: Data consists of the a mapping of practice to parent PCN, to parent sub-ICB (prev. CCG), to parent ICB, to parent NSH England region

### PCN data

Source: [NHS Digital](https://digital.nhs.uk/)

Landing Page: [GP and GP practice related data](https://digital.nhs.uk/services/organisation-data-service/export-data-files/csv-downloads/gp-and-gp-practice-related-data)

Example Data: [July 2023 data](https://digital.nhs.uk/binaries/content/assets/website-assets/services/ods/data-downloads-other-nhs-organisations/epcn.zip)

Notes: Data contains the postcode of the lead practice for each PCN for geocoding

### Postcode data

Source: [Office for National Statistics](https://geoportal.statistics.gov.uk/)

Landing Page: [ONS Postcode Directory](https://geoportal.statistics.gov.uk/search?collection=Dataset&sort=-created&tags=all(PRD_ONSPD%2CMAY_2023))

Example Data: [May 2023 data](https://geoportal.statistics.gov.uk/datasets/ons-postcode-directory-may-2023)

Notes: Data contains the latitude and longitude of postcode centroid for geocoding along with the corresponding output area (OA) and lower-layer super output area (LSOA) for 2011 and 2021 mapping.

----

## Methodology

### Practice catchment area

The `gp-reg-pat-prac-lsoa-all.csv` file is extracted from the GP registration data zip file and the data consists of the following fields

 - `PUBLICATION` - the name of the publication (**GP_PRAC_PAT_LIST**)
 - `EXTRACT_DATE` -  the extract date
 - `PRACTICE_CODE` - the GP practice code
 - `PRACTICE_NAME` - the GP practice name
 - `LSOA_CODE` - the lower-layer super output area (LSOA) 2011 code
 - `SEX` - the gender of the patient (**ALL**)
 - `NUMBER_OF_PATIENTS` - the number of registered patients

The data is filtered by entries that have an `LSOA_CODE` that begins with **E** signifying an English LSOA (excluding patients from unknown LSOAs and also those residing in Wales) and only the `PRACTICE_CODE`, `LSOA_CODE` and `NUMBER_OF_PATIENTS` fields are used.

This data is grouped by `LSOA_CODE` and the `TOTAL_REGISTERED_PATIENTS` for the LSOA is calculated as the sum of all patients from that LSOA registered with any practice.

This grouped data is combined with the practice level data to obtain a data set consisting of `PRACTICE_CODE`, `LSOA_CODE`, `NUMBER_OF_PATIENTS` and `TOTAL_REGISTERED_PATIENTS`. The `PCT_REGISTERED_PATIENTS` field is calculated as the `NUMBER_OF_PATIENTS` divided by the `TOTAL_REGISTERED_PATIENTS`.

### PCN catchment area

The `gp-reg-pat-prac-lsoa-all.csv` file is extracted from the GP registration data zip file and the data consists of the following fields

 - `PUBLICATION` - the name of the publication (**GP_PRAC_PAT_LIST**)
 - `EXTRACT_DATE` -  the extract date
 - `PRACTICE_CODE` - the GP practice code
 - `PRACTICE_NAME` - the GP practice name
 - `LSOA_CODE` - the lower-layer super output area (LSOA) 2011 code
 - `SEX` - the gender of the patient (**ALL**)
 - `NUMBER_OF_PATIENTS` - the number of registered patients

The data is filtered by entries that have an `LSOA_CODE` that begins with **E** signifying an English LSOA (excluding patients from unknown LSOAs and also those residing in Wales) and only the `PRACTICE_CODE`, `LSOA_CODE` and `NUMBER_OF_PATIENTS` fields are used.

This data is joined to the Practice, PCN, Sub-ICB, ICB, NHSE Region lookup data to get the `PCN_CODE` for each `PRACTICE_CODE`. This data is then grouped by `PCN_CODE` and `LSOA_CODE` and the `NUMBER_OF_PATIENTS` summed to obtain the `NUMBER_OF_PATIENTS` by PCN.

This data is grouped by `LSOA_CODE` and the `TOTAL_REGISTERED_PATIENTS` for the LSOA is calculated as the sum of all patients from that LSOA registered with any PCN (and also those practices not members of any PCN, U - unallocated).

This grouped data is combined with the PCN level data to obtain a data set consisting of `PCN_CODE`, `LSOA_CODE`, `NUMBER_OF_PATIENTS` and `TOTAL_REGISTERED_PATIENTS`. The `PCT_REGISTERED_PATIENTS` field is calculated as the `NUMBER_OF_PATIENTS` divided by the `TOTAL_REGISTERED_PATIENTS`.

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

### Practice catchment

The data frame name is `df_prac_catchment` and this provides the proportion of each LSOA's registered population by practice and the fields are as follows

 - `PRAC_CODE` - practice code
 - `LSOA11CD` - LSOA 2011 code
 - `REG_POPN` - registered population
 - `TOTAL_REG_POPN` - total registered population for LSOA
 - `PCT` - registered population as proportion of total registered population

### PCN catchment

The data frame name is `df_pcn_catchment` and this provides the proportion of each LSOA's registered population by PCN and the fields are as follows

 - `PCN_CODE` - PCN code
 - `LSOA11CD` - LSOA 2011 code
 - `REG_POPN` - registered population
 - `TOTAL_REG_POPN` - total registered population for LSOA
 - `PCT` - registered population as proportion of total registered population

### Lookup

The data frame name is `df_lu` and this provides the lookup data for each practice and 

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

