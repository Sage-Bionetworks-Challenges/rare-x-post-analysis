# Install all R packages if not yet --------------------------
source("install.R")

# Set up synapse ----------------------------------------------------------
reticulate::use_condaenv('synapse')
synapseclient <- reticulate::import('synapseclient')
syn <- synapseclient$Synapse()
syn$login(silent = TRUE)


# Set up task variables --------------------------------------------------------
view_id <- "syn52141680" #Task submissions Table synID
eval_id <- "9615381" #Task eval queue ID in parentheses
gs_id <- list("syn52069274", "syn52069273") #Gold Standard files
#metrics_lookup <- list(c("nrmse_score", "spearman_score"), 
                       #c("summed_score", "jaccard_similarity"))


# Set up cores for parallization ------------------------------------------
ncores <- parallel::detectCores() - 1
message("<<<< ", ncores, " cores will be used for parallel computing if applicable", " <<<<")



# Set up output directory -------------------------------------------------
data_dir <- "data"
dir.create(data_dir, showWarnings = FALSE)

