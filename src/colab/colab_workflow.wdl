version 1.0
#WORKFLOW DEFINITION
workflow mhubai_workflow {
 input {
   #all the inputs entered here but not hardcoded will appear in the UI as required fields
   #And the hardcoded inputs will appear as optional to override the values entered here
   File jsonServiceAccountFile
   String projectID
   String MHUB_MODEL_NAME
   String docker = "imagingdatacommons/idc-testing-colab"
   Int preemptibleTries = 3
   Int cpus = 4
   Int ram = 16
   String gpuType = 'nvidia-tesla-t4'
   String zones = "europe-west2-a europe-west2-b asia-northeast1-a asia-northeast1-c asia-southeast1-a asia-southeast1-b asia-southeast1-c us-east4-a us-east4-b us-east4-c" 
 }
 #calling Papermill Task with the inputs
 call executor{
   input:
    jsonServiceAccountFile = jsonServiceAccountFile,
    projectID = projectID,
    MHUB_MODEL_NAME = MHUB_MODEL_NAME,
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
   File? outputNotebook = executor.outputNotebook
 }
}

#Task Definitions
task executor{
 input {
   #Just like the workflow inputs, any new inputs entered here but not hardcoded will appear in the UI as required fields
    File jsonServiceAccountFile
    String projectID
    String MHUB_MODEL_NAME
    String docker
    Int preemptibleTries
    Int cpus
    Int ram
    String gpuType 
    String zones
 }
 command {
   export GOOGLE_APPLICATION_CREDENTIALS=~{jsonServiceAccountFile}
   mkdir /content
   cd /content
   NOTEBOOK_URL="https://raw.githubusercontent.com/MHubAI/examples/main/notebooks/MICCAI23_tutorial.ipynb"
   wget $NOTEBOOK_URL -O notebook.ipynb  # Save the notebook with a fixed name
   wget https://raw.githubusercontent.com/vkt1414/mhubai-unleashed/main/preProcessNotebooks.py
   python3 preProcessNotebooks.py --file-name=notebook.ipynb  # Pass the fixed name to your script
   pip install papermill
   papermill -p MHUB_MODEL_NAME ~{MHUB_MODEL_NAME} -p GC_PROJECT_ID  ~{projectID} notebook.ipynb outputNotebook.ipynb
   mv /content/outputNotebook.ipynb /content/*.zip /cromwell_root
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
   File? outputNotebook = "outputNotebook.ipynb"
   File? outputZip  = "*.zip"
 }
}
