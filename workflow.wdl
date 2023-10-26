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
   mkdir content
   cd content
   NOTEBOOK_URL="https://raw.githubusercontent.com/MHubAI/examples/main/notebooks/MICCAI23_tutorial.ipynb"
   wget $NOTEBOOK_URL -O notebook.ipynb  # Save the notebook with a fixed name
   wget https://raw.githubusercontent.com/vkt1414/mhubai-unleashed/main/preProcessNotebooks.py
   python3 preProcessNotebooks.py --file-name=notebook.ipynb  # Pass the fixed name to your script
   pip install papermill
   papermill -p MHUB_MODEL_NAME ~{MHUB_MODEL_NAME} notebook.ipynb outputNotebook.ipynb  # Use the fixed name here too
 }
 #Run time attributes:
 runtime {
   docker: docker
   cpu: cpus
   cpuPlatform: cpuFamily
   zones: zones
   memory: ram + " GiB"
   disks: "local-disk 50 HDD" 
   preemptible: preemptibleTries
   maxRetries: 3
 }
 output {
   File outputNotebook = "outputNotebook.ipynb"
   File outputZip  = "*.zip"
 }
}
