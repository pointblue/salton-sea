# Script to create raster covariate layers from csv file and uid grids

# Packages
library(terra)

# Functions to add a timestamp to messages
add_ts <- function(...) paste0("[", Sys.time(), "] - ", ...)
message_ts <- function(...) message(add_ts(...))

# Directories
base_dir <- getwd() #change as needed
uid_dir <- file.path(base_dir, "uid_grids")
cov_dir <- file.path(base_dir, "covariates")

# Load uid grids
uid_500m_rst <- rast(file.path(uid_dir, "salton5km_uid_500m.tif"))
uid_5000m_rst <- rast(file.path(uid_dir, "salton5km_uid_5000m.tif"))

# Load covariates file
cov_cmb_df <- read.csv(file.path(cov_dir, "covariates_combined.csv"))
cov_500m_df <- read.csv(file.path(cov_dir, "covariates_500m.csv"))
cov_5000m_df <- read.csv(file.path(cov_dir, "covariates_5000m.csv"))


# Define wanted variables at both scales
vars_500m_only <- c("ClayFraction", "OrganicFraction", "SandFraction", "SiltFraction", 
                    "RiverDistanceMeters_500m", "RiverMouthDistanceMeters_500m",
                    "ElevationMeters_500m", "SlopeDegrees_500m")
vars_both <- c("FreshwaterEmergentSqmNWI", "FreshwaterForestedSqmNWI", "FreshwaterPondSqmNWI",
                "LakeSqmNWI", "RiverineSqmNWI", "OtherWetlandSqmNWI", "NonLakeWetlandTotalSqmNWI",
                "OpenWaterSqmNLCD2011", "DevelopedOpenSqmNLCD2011", "DevelopedLowSqmNLCD2011", 
                "DevelopedMedSqmNLCD2011", "DevelopedHighSqmNLCD2011", "BarrenSqmNLCD2011",
                "ForestDeciduousSqmNLCD2011", "ForestEvergreenSqmNLCD2011", "ForestMixedSqmNLCD2011",
                "ShrubScrubSqmNLCD2011", "HerbaceousSqmNLCD2011", "PastureSqmNLCD2011",
                "CultivatedSqmNLCD2011", "WetlandsWoodySqmNLCD2011", "WetlandsHerbaceousSqmNLCD2011",
                "DevelopedTotalSqmNLCD2011", "AgTotalSqmNLCD2011", "WetlandsTotalSqmNLCD2011")
scales <- c("500m", "5000m")

# Shore and water depth variables are available at a range of lake
# elevations, measured in feet, from 228 - 234 ft
vars_depth <- c("ExposedShoreSqm", "WaterDepthMeters", "WaterShallowsSqm_0to15cm_",
                "WaterShallowsSqm_15to30cm_", "WaterShallowsSqm_30to200cm_", "WaterShallowsSqm_200to1000cm_")
depths <- c("228.0ft")
vars_depths <- paste0(rep(vars_depth, each = length(depths)), depths)

vars_500m <- c(vars_500m_only, paste0(vars_depths, "_500m"))
vars_5000m <- paste0(c(vars_both, vars_depths), "_5000m")

create_covariate_rasters <- function(uid_rst, cov_df, uid_col, vars, out_dir, overwrite = FALSE) {
  
  if (!(uid_col %in% names(cov_df))) {
    stop(add_ts("uid_col ", uid_col, " does not exist in cov_df."))
  }
  var_cols_exist <- vars %in% names(cov_df)
  if (!all(var_cols_exist)) {
    stop(add_ts("Not all variables exist in cov_df.  Missing:\n\t", paste0(vars[!var_cols_exist], collapse = "\n\t")))
  }
  
  for (v in vars) {
    
    message_ts("Working on variable ", v)
    
    file_out <- file.path(out_dir, paste0(v, ".tif"))
    
    if (file.exists(file_out) & overwrite != TRUE) {
      
      message_ts(file_out, " already created and overwrite != TRUE. Moving to next...")
      
    } else {
      
      message_ts("Creating raster ", file_out, "...")
      rcl_mat <- as.matrix(cov_df[c(uid_col, v)])
      var_rst <- classify(uid_rst, rcl_mat, others = NA)
      writeRaster(var_rst, file_out, overwrite = TRUE)
      
    }
    
  }
  
}

# 500m covariates, clipped to shoreline 
create_covariate_rasters(uid_500m_rst, cov_cmb_df, 
                         "UID500m", vars_500m,
                         out_dir = file.path(cov_dir, "rasters_clipped"))

# 5000m covariates, clipped to shoreline 
create_covariate_rasters(uid_5000m_rst, cov_cmb_df, 
                         "UID5000m", vars_5000m,
                         out_dir = file.path(cov_dir, "rasters_clipped"))

# 500m covars, whole grid
create_covariate_rasters(uid_500m_rst, cov_500m_df, 
                         "UID", vars_500m,
                         out_dir = file.path(cov_dir, "rasters_full"))


# 5000m covars, whole grid
create_covariate_rasters(uid_5000m_rst, cov_5000m_df, 
                         "UID", vars_5000m,
                         out_dir = file.path(cov_dir, "rasters_full"))
