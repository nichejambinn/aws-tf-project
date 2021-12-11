# Deployment Steps

S3 bucket whose name matches the one in `/backend.tf` (currently set to `tf-state-group3-project`) that has *blocked* all public access must have already been created to persist the Terraform state. If the current name is taken, `backend.tf` must be modified to match.

The resource `aws_s3_bucket.image_storage` in `/main.tf` must have a unique name. If `tf-image-group3-project` is taken, the bucket property must be changed to something else.

A key pair named `group3admin` must have already been created. The private key .pem file must have its permissions set to readonly in order to ssh into the Bastion hosts.

## Route Table Updates


## Webserver Access
Must have copied the `group3admin` key pair into the Bastion host in order to access the webservers in its VPC using ssh or http.

## Copying from S3
Run this command to permit an EC2 instance to copy a file from an S3 bucket:
`aws ec2 associate-iam-instance-profile --iam-instance-profile Name=LabInstanceProfile --instance-id <instance_id>`

Upload `/images/mountain.jpeg` to the image storage bucket mentioned above.