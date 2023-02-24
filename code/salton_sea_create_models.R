# Script to model bird species occurrence at the Salton Sea
# nelliott@pointblue.org

# Load packages
library(raster) #required for dismo still but planned for 2024 deprecation in favor of terra
library(gbm)
library(dismo)

# Functions to add a timestamp to messages
add_ts <- function(...) paste0("[", Sys.time(), "] - ", ...)
message_ts <- function(...) message(add_ts(...))

# Directories
base_dir <- getwd() #change as needed
bird_dir <- file.path(base_dir, "birds")
uid_dir <- file.path(base_dir, "uid_grids")
model_dir <- file.path(base_dir, "models/weighted_final")

# Load UID grids
uid_500m_rst <- raster(file.path(uid_dir, "salton5km_uid_500m.tif"))
uid_5000m_rst <- raster(file.path(uid_dir, "salton5km_uid_5000m.tif"))

# Load covariate data (by sampling event)
se_df <- read.csv(file.path(bird_dir, "sampling_events_attributed.csv"))

# Remove duplicates (multiple observations on the same date in the same 500m grid cell), as they have the same covariate data
se_df <- se_df[!duplicated(se_df[c("UID500m", "UID5000m", "obsdate")]), ]

# Load bird metadata
# Not actually used here; was used in some versions that grouped species by various characteristics
md_df <- read.csv(file.path(bird_dir, "bird_metadata.csv"))

# Get variables of interest for different models
# Drop landcovers we eliminated in variable testing and exploratory modelling
covar_cols <- names(se_df[9:79])[!grepl("WaterLevel|Developed|Shrub|Forest|Elevation|LakeSqm|Barren|Cultivated|AgTotal|OpenWater", 
                                       names(se_df[9:79]))] #|River.*Distance

# Check duplicates (multiple observations on the same date in the same 500m grid cell)
sum(duplicated(se_df[c("UID500m", "UID5000m", "obsdate")]))

# It is unclear how exactly we handled duplicates.  We know that we discussed taking them out 
# (using either a random survey or the biggest count) and may have done so but are not sure.
# This version of the code (which I think was the final version) does not remove duplicates.

# Loop across files
# Use 0.5km data for most species, 2.5km data for COGA, GBTE, and LEBI
files <- paste0(bird_dir, "/", c(file.path("byTaxon_0.5km", c("AMAV", "AWPE", "BLSK", "BLTE", "DCCO", "DUNL", "EAGR", "GADW", "GULL", 
                                                             "LESA", "MAGO", "NOSH", "RUDU", "SORA", "SNEG", "SNPL", "UNDO", "WESA", 
                                                             "VIRA")),
                                 file.path("byTaxon_2.5km", c("COGA", "GBTE", "LEBI"))),
                ".RData")
for (f in files) {
  
  grp <- strsplit(basename(f), "\\.")[[1]][1]
  message_ts("Creating model for", grp)
  
  # Species-specific learning rate (based on exploratory modelling; VIRA and DUNL performed better with a slower learning rate)
  if (grp == "VIRA" | grp == "DUNL") {
    lr <- 0.001
    tc <- 3
  } else {
    lr <- 0.005
    tc <- 3
  }
  
  # Out file
  mdl_file <- file.path(model_dir, paste0(grp, ".RData"))
  if (file.exists(mdl_file)) {
    message_ts("Model already built. Moving to next...")
    next
  }
  
  # Load bird data
  load(file.path(f))
  
  # Extract uid for each bird observation (spdf contains the species data loaded from file f)
  spdf$UID500m <- extract(uid_500m_rst, spdf[c("lon", "lat")])
  spdf$UID5000m <- extract(uid_5000m_rst, spdf[c("lon", "lat")])
  
  # Remove rows with no uid (outside of study area)
  spdf <- spdf[!is.na(spdf$UID500m) & !is.na(spdf$UID5000m),]

  # Merge covariate data to bird observations by uid and date
  mdl_df <- merge(spdf, se_df, by = c("UID500m", "UID5000m", "obsdate"), all.x = TRUE)
  stopifnot(nrow(mdl_df) == nrow(spdf))
  #mdl_df[duplicated(mdl_df[c("UID500m", "UID5000m", "obsyear.x", "obsmonth.x")]), ] #examine duplicates if found 
  
  # Calc percent 0
  zeroCount <- sum(mdl_df$count == 0)
  zeroPct <- zeroCount / nrow(mdl_df) * 100
  message(paste(zeroCount, "of", nrow(mdl_df), "(", round(zeroPct, 2), "% )", grp, "observations are zeroes"))
  
  # Convert count to presence/absence
  mdl_df$pa <- ifelse(mdl_df$count >= 1, 1, 0)
  y_col <- "pa"
  mdl_fam <- "bernoulli"

  # Create models
  mdl <- gbm.step(mdl_df, gbm.x = covar_cols, gbm.y = y_col, site.weights = mdl_df$weight,
                       tree.complexity = tc, learning.rate = lr, family = mdl_fam, 
                       keep.fold.models = TRUE, keep.fold.vector = TRUE, keep.fold.fit = TRUE, plot.main = FALSE)
  
  # Save models
  save(mdl_df, mdl, file = mdl_file)
  
}
