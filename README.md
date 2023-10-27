# MHUBAI Unleashed

Welcome to the `mhubai-unleashed` repository! This repository hosts WDL (Workflow Description Language) workflows for MHUBAI (Medical Hub AI), providing a structured and scalable way to run complex pipelines.


Please cite MHUBAI as this repo is based on their work:
https://github.com/MHubAI

## Overview

The workflows in this repository are designed to facilitate the execution of MHUBAI tasks, ensuring reproducibility and ease of use.

## Getting Started

To get started with these workflows, follow these steps:

1. Visit our Dockstore page: [MHUBAI Unleashed on Dockstore](https://dockstore.org/workflows/github.com/vkt1414/mhubai-unleashed/mhubaiWorkflowOnTerra:main?tab=info)

2. Import the workflow to a platform of your choice:
   - [DNANexus](https://www.dnanexus.com/)
   - [Terra](https://app.terra.bio/)
   - [elwazi](https://elwazi.org/)
   - [ANVIL](https://anvilproject.org/)
   - [NHLBI BioData Catalyst](https://biocatalyst.nhlbi.nih.gov/)

3. Provide the following inputs:
   - GCP projectID
   - A GCP service account key file with at least a Bigquery User role
   - MHUBAI model name
     
4. A sample data table manifest you can import can be found in the repo
   - [Sample data table manifest](https://github.com/vkt1414/mhubai-unleashed/blob/main/mhubai_workflow.tsv)


