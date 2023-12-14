# MHUBAI Unleashed

Welcome to the `mhubai-unleashed` repository! This repository hosts WDL (Workflow Description Language) workflows for MHUBAI (Medical Hub AI), providing a structured and scalable way to run complex pipelines.


Please cite MHUBAI as this repo is based on their work:
https://github.com/MHubAI

## Overview

The workflows in this repository are designed to facilitate the execution of MHUBAI tasks, ensuring reproducibility and ease of use.

## Getting Started

To get started with these workflows, follow these steps:

1. Visit our Dockstore page: [MHUBAI Unleashed on Dockstore](https://dockstore.org/workflows/github.com/vkt1414/mhubai-unleashed/mhubaiDockerfileWorkflow:main?tab=info)

2. Import the workflow to a platform of your choice:
   - [DNANexus](https://www.dnanexus.com/)
   - [Terra](https://app.terra.bio/)
   - [elwazi](https://elwazi.org/)
   - [ANVIL](https://anvilproject.org/)
   - [NHLBI BioData Catalyst](https://biocatalyst.nhlbi.nih.gov/)

3. Provide the following inputs:
   - MHUBAI model name
   - aws or gcs urls in a txt or csv file, each line containing a single URL (choose one provider but not mix aws and gcp)
     - TIP: If files are downloaded from ImagingDataCommons, all SOPInstances in a series can be referenced by wildcard such as s3://idc-open-data/d0686cc8-0f8b-4e77-8707-605d1d8f7a08/*
   - If you want to override mhubai's default config, provide your custom config in yaml format while submitting the workflow
     
5. A sample data table manifest you can import can be found in the repo
   - [Sample data table manifest](https://github.com/vkt1414/mhubai-unleashed/blob/main/examples/mhubai_workflow.tsv)


