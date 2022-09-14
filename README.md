This is a dev env that spins up Azure resources. This will create a new rg, virtual network, subnet, NSG(sec group, sec rule, sec group associate), publicip, nic, vm (ubuntu18.04) and provisioner. Optionals are; setting up ssh to allow VS code to open a remote terminal in our VM. You can manually ssh to the VM and run scripts in the customdata.tpl manually.  

# VS Code
https://code.visualstudio.com/download

# Install & Configuring Terraform on Windows Systems
Ref: https://docs.oracle.com/en/solutions/infrastructure-components-siebel/ebs-configuring-terraform-windows-systems.html#GUID-1CBCF6B6-322C-4597-8A4A-5FE546F8E21F

# Install Azure CLI (Win) 
Azure Ref:  docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs-azure-cli 

# Add terraform (tf) extension in VS code and create new folder to store files.

Commands:
# terraform format -this will clean our code  
: terraform fmt

# Initializing the backend (local backend). Means where our tf state where everything is stored.
: terraform init

# Creates or updates infrastructure depending on the configuration files.
: terraform apply 

# list all created resources 
: terraform state list  

# will give you info of the resource or view specific resource info 
: terraform state show <resource_name> 

# to show the entire state 
: terraform show 

# this command is to output what is to be destroyed. The "-" dash are those that will be destroyed/deleted. 
: terraform plan -destroy 

# this will destroy (nuked)
: terraform destroy 

# flags used
-refresh-only, -auto-approve, 

#generate key pair and you might to rename your key pair. dont bother with the paraphrase. 
: ssh-keygen -t rsa 
# check the keys 
: ls ~/.ssh/ 

# customdata.tpl where our bash script is.

# for further info please refer to main.tf #notes