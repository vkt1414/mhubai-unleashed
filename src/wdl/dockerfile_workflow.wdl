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
   File awsOrGcsUrls

   #mhub
   String mhub_model_name
   File? mhubai_custom_config

   #VM Config
   Int cpus = 4
   Int ram = 15
   Int preemptibleTries = 3
   String gpuType = 'nvidia-tesla-t4'
   String gpuZones = "europe-west2-a europe-west2-b asia-northeast1-a asia-northeast1-c asia-southeast1-a asia-southeast1-b asia-southeast1-c us-east4-a us-east4-b us-east4-c"
 }
 #calling mhubai_terra_runner
 call mhubai_terra_runner{
   input:
    awsOrGcsUrls = awsOrGcsUrls,

    mhub_model_name = mhub_model_name,
    mhubai_custom_config = mhubai_custom_config,

    #mhubai dockerimages are predictable with the below format
    docker = "vamsithiriveedhi/mhubai_"+mhub_model_name,

    cpus = cpus,
    ram = ram,
    preemptibleTries = preemptibleTries,
    gpuType = gpuType,
    gpuZones = gpuZones
}
 output {
   File? compressedOutputFile = mhubai_terra_runner.compressedOutputFile
 }
}

#Task Definitions
task mhubai_terra_runner{
 input {
   #Just like the workflow inputs, any new inputs entered here but not hardcoded will appear in the UI as required fields

    #CT data
    File awsOrGcsUrls

    #mhub
    String mhub_model_name
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
    && tar -xvzf "s5cmd_2.2.2_Linux-64bit.tar.gz"  s5cmd\ 
    && rm "s5cmd_2.2.2_Linux-64bit.tar.gz" \
    && mv s5cmd /usr/local/bin/s5cmd
    
    # Install lz4 and tar for compressing output files
    apt-get update && apt-get install -y apt-utils lz4 pigz

    #download each series into its crdc_uid folder
    while IFS= read -r line; do
        # Extract the series ID from the URL
        crdc_uid=$(echo $line | cut -d'/' -f4)
        # Copy the files 
        echo "cp --show-progress $line /app/data/input_data/$crdc_uid" >> s5cmd_manifest.txt
    done < ~{awsOrGcsUrls}
    
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
    #python3 -m mhubio.run --config /app/models/~{mhub_model_name}/config/default.yml
    python3 -m mhubio.run --config ~{select_first([mhubai_custom_config, "/app/models/" + mhub_model_name + "/config/default.yml"])} --print
    
    # Compress output data and move it to Cromwell root directory
    tar -C /app/data -cvf - output_data | lz4 > /cromwell_root/output.tar.lz4
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
   nvidiaDriverVersion: "525.147.05"
 }
 output {
   File? compressedOutputFile  = "output.tar.lz4"
 }
}
