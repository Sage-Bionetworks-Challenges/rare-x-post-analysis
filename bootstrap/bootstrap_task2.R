source("utils/setup.R")

task_n <- 2

sub_data <- file.path(data_dir, str_glue("final_scores_task{task_n}.rds"))

# confirm that the final submission task file exists or create it
if (!file.exists(sub_data)) source("submission/get_submissions.R")


# Download predictions ----------------------------------------------------
sub_df <- readRDS(
  file.path(data_dir, str_glue("final_scores_task{task_n}.rds"))
)


for (n in 1:nrow(sub_df)) { 
  
  # intialize submission ID, prediction file ID and team names
  sub_id <- sub_df$id[n]
  pred_id <- sub_df$prediction_fileid[n]
  team <- as.character(sub_df$team[n])
  
  #create subfolder in data directory for each team
  output_dir <- file.path(data_dir, "model_output")
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  # add subfolders in model_output directory for each team
  pred_dir <- file.path(output_dir, str_glue("{team}_{sub_id}_task{task_n}"))
  
  message("\n")
  message("------------------------------------------")
  message("Retrieving prediction files from ", team, " ...")
  message("------------------------------------------")
  
  if (!dir.exists(pred_dir)) {
    pred_path <- syn$get(pred_id)$path
    dir.create(pred_dir, showWarnings = FALSE, recursive = TRUE)
    untar(pred_path, exdir = pred_dir, verbose = TRUE)
    unlink(pred_path) # remove cache to save space
  }
  
  message("Done {n}/{nrow(sub_df)}")
}