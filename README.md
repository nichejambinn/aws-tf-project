S3 bucket named `tf-state-group3-project` that has *blocked* all public access must have already been created to persist the Terraform state.

Key pair pem file named `group3admin` must have already been created and permissions set to readonly in order to ssh into the Bastion hosts.

Must have copied the `group3admin` key pair into each Bastion host in order to access the webservers using ssh or http.