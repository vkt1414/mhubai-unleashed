# This WDL script is designed to run any models abstracted by mhubai
# This wdl workflow takes several inputs including the model name, custom configuration file, and resource specifications (CPUs, RAM, GPU type).
# It then calls the task (mhubai_terra_runner) with these inputs.

# The mhubai_terra_runner task first installs necessary tools (s5cmd for data download and lz4 for compression), 
# then downloads the data from either AWS S3 or Google Cloud Storage (GCS). 
# After that, it runs the models using the mhubio.run command with the provided model name and configuration file. 
# Finally, it compresses the output data and moves it to the Cromwell root directory.

# The runtime attributes specify the Docker image to use, CPU and memory resources, disk type and size, 
# number of preemptible tries and retries, GPU type and count, and the zones where to run the task.

version 1.0
#WORKFLOW DEFINITION
workflow mhubai_workflow {
 input {
   #all the inputs entered here but not hardcoded will appear in the UI as required fields
   #And the hardcoded inputs will appear as optional to override the values entered here

   #CT data
   File seriesInstanceS5cmdUrls

   String dicomsegAndRadiomicsSR_Docker = "imagingdatacommons/dicom_seg_pyradiomics_sr"


   #mhub
   File? mhubai_custom_config

   #VM Config
   Int cpus = 2
   Int ram = 13

   Int preemptibleTries = 3
   Int dicomsegAndRadiomicsSR_PreemptibleTries = 3

   Int dicomsegAndRadiomicsSR_Cpus = 4
   Int dicomsegAndRadiomicsSR_RAM = 16

   String dicomsegAndRadiomicsSR_CpuFamily = 'AMD Rome' 

   String gpuType = 'nvidia-tesla-t4'
   String gpuZones = "us-west4-a us-west4-b us-east4-a us-east4-b us-east4-c europe-west2-a europe-west2-b asia-northeast1-a asia-northeast1-c asia-southeast1-a asia-southeast1-b asia-southeast1-c europe-west4-a europe-west4-b europe-west4-c"
   String dicomsegAndRadiomicsSR_Zones = "asia-northeast2-a asia-northeast2-b asia-northeast2-c europe-west4-a europe-west4-b europe-west4-c europe-north1-a europe-north1-b europe-north1-c us-central1-a us-central1-b us-central1-c us-central1-f us-east1-b us-east1-c us-east1-d us-west1-a us-west1-b us-west1-c"
 }
 #calling mhubai_terra_runner
 call mhubai_terra_runner{
   input:
    seriesInstanceS5cmdUrls = seriesInstanceS5cmdUrls,
    mhubai_custom_config = mhubai_custom_config,
    docker = "vamsithiriveedhi/mhubai_totalsegmentator",
    cpus = cpus,
    ram = ram,
    preemptibleTries = preemptibleTries,
    gpuType = gpuType,
    gpuZones = gpuZones
}
call dicomsegAndRadiomicsSR{
   input:
    seriesInstanceS5cmdUrls = seriesInstanceS5cmdUrls,
    dicomsegAndRadiomicsSR_Docker = dicomsegAndRadiomicsSR_Docker,
    dicomsegAndRadiomicsSR_PreemptibleTries = dicomsegAndRadiomicsSR_PreemptibleTries,
    dicomsegAndRadiomicsSR_Cpus = dicomsegAndRadiomicsSR_Cpus,
    dicomsegAndRadiomicsSR_RAM = dicomsegAndRadiomicsSR_RAM,
    dicomsegAndRadiomicsSR_Zones = dicomsegAndRadiomicsSR_Zones,
    dicomsegAndRadiomicsSR_CpuFamily = dicomsegAndRadiomicsSR_CpuFamily,
    #Nifti files converted in the first step are provided as input here
    inferenceZipFile = mhubai_terra_runner.compressedOutputFile
}
 output {
   File? logs = mhubai_terra_runner.logs
   File dicomsegAndRadiomicsSR_OutputNotebook = dicomsegAndRadiomicsSR.dicomsegAndRadiomicsSR_OutputJupyterNotebook   
   File dicomsegAndRadiomicsSR_UsageMetrics  = dicomsegAndRadiomicsSR.dicomsegAndRadiomicsSR_UsageMetrics
   File dicomsegAndRadiomicsSR_CompressedFiles = dicomsegAndRadiomicsSR.dicomsegAndRadiomicsSR_CompressedFiles
   File pyradiomicsRadiomicsFeatures = dicomsegAndRadiomicsSR.pyradiomicsRadiomicsFeatures
   File structuredReportsDICOM = dicomsegAndRadiomicsSR.structuredReportsDICOM
   File structuredReportsJSON = dicomsegAndRadiomicsSR.structuredReportsJSON
   File? dicomsegAndRadiomicsSR_Errors = dicomsegAndRadiomicsSR.dicomsegAndRadiomicsSR_SRErrors

 }

}

#Task Definitions
task mhubai_terra_runner{
 input {
   #Just like the workflow inputs, any new inputs entered here but not hardcoded will appear in the UI as required fields

    #CT data
    File seriesInstanceS5cmdUrls

    #mhub
    File? mhubai_custom_config

    String docker

    #VM Config
    Int cpus
    Int ram
    Int preemptibleTries
    String gpuType 
    String gpuZones
 }
 command {
    # Install s5cmd
    wget -q "https://github.com/peak/s5cmd/releases/download/v2.2.2/s5cmd_2.2.2_Linux-64bit.tar.gz" \
    && tar -xvzf "s5cmd_2.2.2_Linux-64bit.tar.gz" s5cmd \
    && rm "s5cmd_2.2.2_Linux-64bit.tar.gz" \
    && mv s5cmd /usr/local/bin/s5cmd

    
    # Install lz4 and tar for compressing output files
    apt-get update && apt-get install -y lz4 pigz
    
    # Get the column number of s5cmdUrls
    col_num=$(head -n 1 ~{seriesInstanceS5cmdUrls} | tr ',' '\n' | grep -n 's5cmdUrls' | cut -d: -f1)

    # Extract the s5cmdUrls column without the header
    tail -n +2 ~{seriesInstanceS5cmdUrls} | cut -d',' -f$col_num > s5cmd_manifest.txt

    # Download the data assuming aws_urls
    s5cmd --no-sign-request --endpoint-url https://s3.amazonaws.com run s5cmd_manifest.txt
    
    # If aws_urls did not work, try downloading from gcs_urls
    if [ $? -ne 0 ]; then
        echo "S3 command failed, trying GCS..."
        s5cmd --no-sign-request --endpoint-url https://storage.googleapis.com run s5cmd_manifest.txt
    fi
    
    # mhub uses /app as the working directory, so we try to simulate the same
    cd /app
    
    # Run mhubio.run with the provided config or the default config
    python3 -m mhubio.run --config ~{select_first([mhubai_custom_config, "/app/models/totalsegmentator/config/default.yml"])} --debug
    
    # Compress output data and move it to Cromwell root directory
    tar -C /app/data -cvf - output_data | lz4 > /cromwell_root/output.tar.lz4
    tar -C /app/data/_global -cvf - mhub_log | lz4 > /cromwell_root/mhub_log.tar.lz4
    mv /app/data/output_data/* /cromwell_root/
 }
 #Run time attributes:
 runtime {
   docker: docker
   cpu: cpus
   zones: gpuZones
   memory: ram + " GiB"
   bootDiskSizeGb: 50
   disks: "local-disk 10 HDD" 
   preemptible: preemptibleTries
   gpuType: gpuType 
   gpuCount: 1
   #nvidiaDriverVersion: "525.147.05"
 }
 output {
   File compressedOutputFile  = "output.tar.lz4"
   File? logs = "mhub_log.tar.lz4"
 }
}
#Task Definitions
task dicomsegAndRadiomicsSR{
 input {
   #Just like the workflow inputs, any new inputs entered here but not hardcoded will appear in the UI as required fields
   #And the hardcoded inputs will appear as optional to override the values entered here
    File seriesInstanceS5cmdUrls 
    String dicomsegAndRadiomicsSR_Docker
    Int dicomsegAndRadiomicsSR_PreemptibleTries 
    Int dicomsegAndRadiomicsSR_Cpus 
    Int dicomsegAndRadiomicsSR_RAM 
    String dicomsegAndRadiomicsSR_Zones 
    String dicomsegAndRadiomicsSR_CpuFamily

    File inferenceZipFile
 }
 command {
   wget -q https://raw.githubusercontent.com/vkt1414/mhubai-unleashed/main/src/radiomics_notebook/mhub_dicomsegAndRadiomicsSR_Notebook.ipynb
   
   set -o xtrace
   # For any command failures in the rest of this script, return the error.
   set -o pipefail
   set +o errexit
   
   papermill -p csvFilePath ~{seriesInstanceS5cmdUrls} -p inferenceNiftiFilePath ~{inferenceZipFile}  mhub_dicomsegAndRadiomicsSR_Notebook.ipynb mhub_dicomsegAndRadiomicsSR_Notebook.ipynb
   
   set -o errexit
   exit $?
 }

 #Run time attributes:
 runtime {
   docker: dicomsegAndRadiomicsSR_Docker
   cpu: dicomsegAndRadiomicsSR_Cpus
   cpuPlatform: dicomsegAndRadiomicsSR_CpuFamily
   zones: dicomsegAndRadiomicsSR_Zones
   memory: dicomsegAndRadiomicsSR_RAM + " GiB"
   disks: "local-disk 10 HDD"  #ToDo: Dynamically calculate disk space using the no of bytes of yaml file size. 64 characters is the max size I found in a seriesInstanceUID
   preemptible: dicomsegAndRadiomicsSR_PreemptibleTries
   maxRetries: 1
 }
 output {
   File dicomsegAndRadiomicsSR_OutputJupyterNotebook = "mhub_dicomsegAndRadiomicsSR_Notebook.ipynb"
   File dicomsegAndRadiomicsSR_CompressedFiles = "dicomsegAndRadiomicsSR_DICOMsegFiles.tar.lz4"
   File pyradiomicsRadiomicsFeatures = "pyradiomicsRadiomicsFeatures.tar.lz4"
   File structuredReportsDICOM = "structuredReportsDICOM.tar.lz4"
   File structuredReportsJSON = "structuredReportsJSON.tar.lz4"
   File dicomsegAndRadiomicsSR_UsageMetrics = "dicomsegAndRadiomicsSR_UsageMetrics.lz4"
   File? dicomsegAndRadiomicsSR_RadiomicsErrors = "radiomics_error_file.txt"
   File? dicomsegAndRadiomicsSR_SRErrors = "sr_error_file.txt"   
   
 }
}
