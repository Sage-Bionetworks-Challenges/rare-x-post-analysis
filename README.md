# rare-x-post-analysis

# Multi-seq-Data-Analysis-Post-Analysis

Post-hoc analysis for [RARE-X A Rare Disease Open Science Data Challenge](https://www.synapse.org/#!Synapse:syn51198355/wiki/621435)

## Installation

1.  Clone the repo

        git clone https://github.com/Sage-Bionetworks-Challenges/rare-x-post-analysis
        cd rare-x-post-analysis

2.  Create a [conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html#regular-installation) environment using python 3.9:

        conda create --name synapse python=3.9 -y
        conda activate synapse

3.  Install Python dependencies

        python -m pip install challengeutils==4.2.0

    check if `synapseclient` and `challengeutils` are installed via:

        synapse --version
        challengeutils -v

4.  Install R dependencies

        R -e 'source("install.R")'

    > **Note:** <br>
    > The task 2 analysis uses `bedr` package that has two requisitions - [bedpos](https://anaconda.org/bioconda/bedops) and [tabix](https://anaconda.org/bioconda/tabix) needed to be installed as well.

5.  Set up Synapse credentials via CLI, or manually store the credentials to `~/.synapseConfig` - see details [here](https://help.synapse.org/docs/Client-Configuration.1985446156.html)
    synapse login --rememberMe

## Usage

Download all final submission results and each individual test case's scores to `data/` folder:

    Rscript submission/get_submissions.R

- `final_submissions_{task}.rds`: Essential information of final submission, e.g submission id, team, ranks
- `final_scores_{task}.rds`: All accuracy readings from final submissions

Download output files (imputed gene expression / called peaks) of all final submissions to `data/model_output/`

    Rscript submission/get_predictions_{task2}.R
