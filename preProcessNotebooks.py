import subprocess
import nbformat

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
            cell.source = cell.source.replace('auth.authenticate_user()', '#while testing, the authentication is handled by using application default credentials\n#auth.authenticate_user()')         
            
            # Check if the cell contains the specific string and add a tag
            if 'MHUB_MODEL_NAME = "lungmask"       # @param {type:"string"}' in cell.source:
                if 'tags' in cell.metadata:
                    cell.metadata['tags'].append('parameters')
                else:
                    cell.metadata['tags'] = ['parameters']

    # Write the notebook back to disk
    with open(file_name, 'w') as f:
        nbformat.write(nb, f)

# Call the function
modify_notebook(file_name)
