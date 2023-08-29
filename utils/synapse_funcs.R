# Check if a synapse team --------------------------
is_team <- function(syn, uid) {
  if (missing(syn)) stop('argument "syn" is missing')
  if (missing(uid)) stop('argument "uid" is missing')
  out <- tryCatch(
    {
      syn$getTeam(uid)
      return(TRUE)
    },
    error = function(e) FALSE
  )
  return(out)
}


# Check if a synapse user --------------------------
is_user <- function(syn, uid) {
  if (missing(syn)) stop('argument "syn" is missing')
  if (missing(uid)) stop('argument "uid" is missing')
  out <- tryCatch(
    {
      syn$getUserProfile(uid)
      return(TRUE)
    },
    error = function(e) FALSE
  )
  return(out)
}


# Check if a user is part of an existing team --------------------------
is_member <- function(syn, user_uid, team_uid) {
  if (missing(user_uid)) stop('argument "user_uid" is missing')
  if (missing(team_uid)) stop('argument "team_uid" is missing')
  tryCatch(
    {
      member_uids <- reticulate::iterate(syn$getTeamMembers(team_uid)) %>%
        sapply(., function(member_object) {
          member <- jsonlite::fromJSON(as.character(member_object))
          return(member$member$ownerId)
        })
      if (length(member_uids) == 0) {
        return(FALSE)
      } else {
        return(user_uid %in% member_uids)
      }
    },
    error = function(e) FALSE
  )
}


# Check if users are part of existing teams --------------------------
validate_users <- function(syn, users, teams, .drop = FALSE) {
  res <- sapply(users, function(user) {
    if (is_user(syn, user)) { # only validate user
      
      team_res <- sapply(teams, function(team) {
        is_member(syn = syn, user_uid = user, team_uid = team)
      })
      return(any(team_res))
    } else {
      return(FALSE)
    }
  })
  
  if (.drop) {
    res <- res[res]
  }
  return(res)
}


# Retrieve the user/team display name --------------------------
get_name <- function(syn, id) {
  name <- tryCatch(
    {
      syn$getUserProfile(id)$userName
    },
    error = function(err) {
      syn$getTeam(id)$name
    }
  )
  return(name)
}


# Resubmit docker models using synapseclient --------------------------
# Not working for the projects without access
# resubmit <- function(syn, sub_id, new_eval_id) {
#   # resubmit the model without minimal requirements for the request
#   # no teamId, contributors or eligibilityStateHash
#   # note, it only works for the projects with write access
#   sub <- syn$getSubmission(sub_id)
#
#   submission <- list(
#     'evaluationId' = new_eval_id,
#     'name' = sub_id,
#     'entityId' = sub["entityId"],
#     'versionNumber' = sub$get('versionNumber', 1),
#     'dockerDigest' = sub["dockerDigest"],
#     'dockerRepositoryName' = sub["dockerRepositoryName"],
#     'teamId' = NULL,
#     'contributors' = NULL,
#     'submitterAlias' = NULL
#   )
#
#   docker_repo_entity <- syn$restGET(stringr::str_glue('/entity/dockerRepo/id?repositoryName={sub["dockerRepositoryName"]}'))
#   entity <- syn$get(docker_repo_entity["id"], downloadFile=FALSE)
#   uri <- stringr::str_glue("/evaluation/submission?etag={entity['etag']}")
#
#   # ignore eligibility
#   # eligibility <- syn$restGET(stringr::str_glue('/evaluation/{sub["evaluationId"]}/team/{sub["teamId"]}/submissionEligibility'))
#   # uri <- stringr::str_glue("{uri}&submissionEligibilityHash={eligibility['eligibilityStateHash']}")
#   submitted <- syn$restPOST(uri, jsonlite::toJSON(submission, auto_unbox = TRUE, null = "null"))
#   return(submitted)
# }


# Copy and collect docker models to other project --------------------------
copy_model <- function(image, project_id, name, tag = "latest") {
  
  # get new project repo
  docker_repo <- stringr::str_glue("docker.synapse.org/{project_id}")
  
  # TODO: add validation on image string
  
  # get docker image names
  repo_name <- file.path(docker_repo, name)
  new_image <- stringr::str_glue("{repo_name}:{tag}")
  
  system(stringr::str_glue("docker pull {image}"))
  system(stringr::str_glue("docker tag {image} {new_image}"))
  system(stringr::str_glue("docker push {new_image}"))
  system(stringr::str_glue("docker image rm {image} {new_image}"))
  
  return(list(repo_name = repo_name, tag = tag))
}


get_ranked_submissions <- function(syn, query) {

  # download the submissions ordered by overall rank
  sub_df <- syn$tableQuery(query)$asDataFrame() %>%
    mutate(across(everything(), as.character),
           team = as.character(sapply(submitterid, get_name, syn = syn)))
  return(sub_df)
}


# Retrieving scores from submission view table --------------------------
get_scores <- function(syn, sub_df) {
  # validate if any valid submission to prevent from failing
  stopifnot(nrow(sub_df) > 0)

  #score_id <- colnames(sub_df)
  # create df with the accuracy and submitter ids grouped by the submitter id to determine max accuracy
  
  score_id <- sub_df[, c("id", "team", "submitterid", "accuracy", "dockerrepositoryname", "dockerdigest", "admin_folder", "prediction_fileid")] %>%
  arrange(desc(accuracy))
#   group_by(submitterid) %>%
#   arrange(submitterid, accuracy) %>%
#   )
  
  # get the top accuracy results and remove all others
  #score_id <- score_id[score_id$accuracy == score_id$overall_rank, ] #%>%
  #distinct() %>%
  #arrange(desc(overall_rank))

  #remove unneccesary columns
  #score_id <- score_id %>% select(-(accuracy))

  return(score_id)
}


# Rank accuracy across all submissions --------------------------
rank_submissions <- function(accuracy, submitterid) { # function(scores, primary_metric, secondary_metric, group=c("id", "team")) {
  stopifnot(nrow(accuracy) > 0)
  # not looking into a file only taking the accuracy score
  # stopifnot(c(primary_metric, secondary_metric, "dataset") %in% colnames(scores))
  #stopifnot(group %in% colnames(accuracy))
  # rank the accuracy
  rank_df <-
    accuracy %>%
    group_by(submitterid) # %>%
    # rank accuracy of one submission compared to all submissions
    # the smaller values, the smaller ranks, aka higher ranks
    # mutate(
    #   testcase_primary_rank = rank(-(!!sym(accuracy))) #,
    #   # testcase_secondary_rank = rank(-(!!sym(secondary_metric)))
    # ) #%>%
    # group_by_at(submitterid) %>%
    # get average scores of all testcases ranks in one submission
    # summarise(
    #     primary_rank = max(testcase_primary_rank),
    #   # primary_rank = mean(testcase_primary_rank),
    #   # secondary_rank = mean(testcase_secondary_rank),
    #   .groups = "drop"
    # ) %>%
    # rank overall rank on primary, tie breaks by secondary
    # arrange(primary_rank, secondary_rank) %>%
    #arrange(testcase_primary_rank) %>%
    #mutate(overall_rank = row_number())
  
  return(rank_df)
}