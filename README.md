# salton-sea
Code and data from a 2016 analysis of bird populations at the Salton Sea, CA

# Overview
We used a 0.5 km grid to record the number of birds of each species detected in each survey conducted in each cell. 
Based on these counts, we assigned 0/1 to presence/absence of a species in each cell for each survey conducted during the 
year and survey period (starting and ending months). So, a cell may have one to many 0’s and many 1’s if: during the years 
and months considered it was visited once or many times as part of a PFSS or eBird survey (there were other data, some we 
could not even get because there was someone with a grudge, I recall). So, a 0 means “a survey was conducted, and the species 
was not detected in the cell”. A 1 means “a survey conducted, and the species detected in the cell.” We weighted the observations 
so that a non-detection (i.e., a 0) had a weight of 1, and a detection was weighted by the log of the count. The weights 
(or rather, their inverse) were then used for the BRT. The idea of the weights was to add more certainty to a presence if 
the numbers were larger, as it shows a stronger preference by the species for the location.

# Files Included
Full bird data are in RData files in several formats.  The birds directory has three files containing data for all species,
additionally broken out into different the two different sampling resolutions (0.5 and 2.5km).  These differ in the spatial 
resolution used to filter and process the observations.
In the all species files, there are 
  * df -- eBird data
  * dfss -- Salton Sea survey data from Tom Anderson of UFWS; salton_sea_survey_data folder for metadata and excel format
  * effort -- effort data for eBird surveys
  * obs.filtered  -- observations filtered by criteria including: location, survey duration < 241, and months Nov - Apr 
	These are in addition to the filters used when downloading eBird data, which included survey completeness, 
	survey type, and bounding rectangle.
  * obsdata -- data about the eBird observation

In the byTaxon files, data are filtered as above and limited to a single species. There are three objects in each:
  * effsp is the effort data
  * obssp is the non-zero counts
  * spdf is the combined data, including non-zero counts, and calculated weighting for models

Each bird sampling event is attributed with covariate data in birds/sampling_events_attributed.csv.

The birds/plots folder has two plots showing the distribution of effort and presence.

The raw Salton Sea survey data from Tom Anderson at USFWS in the folder birds/salton_sea_survey_data
  * SS NWR PC README.txt -- metadata
  * SS NWR Point Count 2000 to 2011 + CBC DSCooper organized.xls -- data

Covariates are stored in a csv file (covariates/covariates_combined.csv).
  * The first column (UID500m) specifies the spatial grid cell to which the data applies. These are mapped 
    in the values of raster uid_grids/salton5km_uid_500m_latlon.tif.
  * Subsequent columns contain the value for the named covariate.

salton_sea_create_models.R contains the code we used to create the BRTs using the gbm and dismo packages. This code was 
for the final round of presence/absence modelling we did.  

The reports folder contains the final report to funders and technical report, produced Sep 2016.

The models folder is empty and is included so that the code will run as expected.

# Contact
Please contact Nathan Elliott (nelliott@pointblue.org) or Leo Salas (lsalas@pointblue.org) with questions.