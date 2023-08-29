source("utils/setup.R")
source("utils/synapse_funcs.R")


# Download submissions ----------------------------------------------------

# query the final submission, ordered by accuracy
query <- stringr::str_glue(
    "
    SELECT
        id,
        submitterid,
        MAX(accuracy) AS accuracy,
        dockerrepositoryname,
        dockerdigest,
        admin_folder,
        prediction_fileid
    FROM {view_id}
    WHERE
        status = 'ACCEPTED'
        AND submission_status = 'SCORED'
        AND accuracy IS NOT NULL
        AND submitterid <> 3393723 
        AND submitterid <> 3463839
    GROUP BY submitterid
    ORDER BY accuracy
    "
)
    
sub_df <- get_ranked_submissions(syn, query)
    
saveRDS(sub_df, file.path(data_dir, str_glue("final_submissions_task2.rds")))


# Retrieve all scores -----------------------------------------------------
# download all test case's score each submission
sub_df <- readRDS(file.path(data_dir, str_glue("final_submissions_task2.rds")))
    
scores_df <- get_scores(syn, sub_df)

# human readable file listing out the accuracy results in descending order for all participants
write.table(scores_df, "/Users/mdiaz/rare-x-post-analysis/data/scores.txt")
    
saveRDS(scores_df, file.path(data_dir, str_glue("final_scores_task2.rds")))
