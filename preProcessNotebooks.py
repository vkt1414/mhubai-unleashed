import subprocess
import nbformat
import argparse

def modify_notebook(file_name):
    # Load the notebook
    with open(file_name) as f:
        nb = nbformat.read(f, as_version=4)

    # Loop over the cells
    for cell in nb.cells:
        if cell.cell_type == "code":
            # Replace the line if it exists
            cell.source = cell.source.replace('GC_PROJECT_ID = "idc-external-030" # @param {type:"string"}\n', "#this project_id is modified by preprocessingNotebooks.py\nGC_PROJECT_ID=''")
            # Comment out another line
            cell.source = cell.source.replace('auth.authenticate_user()', '#while running the notebook with papermill, the authentication is handled by using application default credentials\n#auth.authenticate_user()')         
            #cell.source = cell.source.replace('/app', '/cromwell_root' + '/app')         
            #cell.source = cell.source.replace('/content', '/cromwell_root/content')  # Adjust this line to replace '/content' with '/cromwell_root/content'         
            cell.source = cell.source.replace('files.download(archive_fn)', '#while running the notebook with papermill, there is no need to download\n#files.download(archive_fn)')   

            # Check if the cell contains the specific string and add a tag
            if 'MHUB_MODEL_NAME = "lungmask"       # @param {type:"string"}' in cell.source:
                if 'tags' in cell.metadata:
                    cell.metadata['tags'].append('parameters')
                else:
                    cell.metadata['tags'] = ['parameters']

    # Write the notebook back to disk
    with open(file_name, 'w') as f:
        nbformat.write(nb, f)

# Create an argument parser
parser = argparse.ArgumentParser(description='Modify a notebook.')
parser.add_argument('--file-name', type=str, help='The name of the file to modify.')

# Parse the arguments
args = parser.parse_args()

# Call the function with the file_name argument
modify_notebook(args.file_name)
