# Deployment Steps

S3 bucket whose name matches the one in `/backend.tf` (currently set to `tf-state-group3-project`) that has *blocked* all public access must have already been created to persist the Terraform state. If the current name is taken, `backend.tf` must be modified to match.

The resource `aws_s3_bucket.image_storage` in `/main.tf` must have a unique name. If `tf-image-group3-project` is taken, the bucket property must be changed to something else.

A key pair named `group3admin` must have already been created. The private key .pem file must have its permissions set to readonly in order to ssh into the Bastion hosts.

## Webserver Access
Must have copied the `group3admin` key pair into the Bastion host in order to access the webservers in its VPC using ssh or http.
