version 1.0
#WORKFLOW DEFINITION
workflow mhubai_workflow {
 input {
   #all the inputs entered here but not hardcoded will appear in the UI as required fields
   #And the hardcoded inputs will appear as optional to override the values entered here
   #String MHUB_MODEL_NAME
   File s5cmdUrls
   String docker = "mhubai/totalsegmentator"
   Int preemptibleTries = 3
   Int cpus = 4
   Int ram = 16
   String gpuType = 'nvidia-tesla-t4'
   String zones = "europe-west2-a europe-west2-b asia-northeast1-a asia-northeast1-c asia-southeast1-a asia-southeast1-b asia-southeast1-c us-east4-a us-east4-b us-east4-c" 
 }
 #calling Papermill Task with the inputs
 call executor{
   input:
    s5cmdUrls = s5cmdUrls,
    #MHUB_MODEL_NAME = MHUB_MODEL_NAME,
    docker = docker,
    preemptibleTries = preemptibleTries,
    cpus = cpus,
    ram = ram,
    gpuType = gpuType,
    #cpuFamily = cpuFamily, 
    zones = zones
}
 output {
  #output notebooks
   File? outputZip = executor.outputZip
 }
}

#Task Definitions
task executor{
 input {
   #Just like the workflow inputs, any new inputs entered here but not hardcoded will appear in the UI as required fields
    File s5cmdUrls
    #String MHUB_MODEL_NAME
    String docker
    Int preemptibleTries
    Int cpus
    Int ram
    String gpuType 
    String zones
 }
 command {
   #install s5cmd
   wget "https://github.com/peak/s5cmd/releases/download/v2.2.2/s5cmd_2.2.2_Linux-64bit.tar.gz" \
   && tar -xvzf "s5cmd_2.2.2_Linux-64bit.tar.gz"\
   && rm "s5cmd_2.2.2_Linux-64bit.tar.gz" \
   && mv s5cmd /usr/local/bin/s5cmd

  apt-get update
  apt-get install -y lz4 tar

  # Read the CSV file line by line
  while IFS= read -r line
  do
    # Modify the line and write to output.txt
    echo "cp --show-progress $line /app/data/input_data" >> s5cmd_manifest.txt
  done < ~{s5cmdUrls}

  s5cmd --no-sign-request --endpoint-url https://s3.amazonaws.com run s5cmd_manifest.txt

  cd /app

  python3 -m mhubio.run --config /app/models/totalsegmentator/config/default.yml

  tar -C /app/data -cvf - output_data | lz4 > /cromwell_root/output.tar.lz4


  mv /app/data/output_data/* /cromwell_root/

  cd /cromwell_root
  ls -R
 }
 #Run time attributes:
 runtime {
   docker: docker
   cpu: cpus
   #cpuPlatform: cpuFamily
   zones: zones
   memory: ram + " GiB"
   disks: "local-disk 50 HDD" 
   preemptible: preemptibleTries
   maxRetries: 3
   gpuType: gpuType 
   gpuCount: 1
 }
 output {
   File? outputZip  = "*.lz4"
 }
}
