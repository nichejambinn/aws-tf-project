# Pre-Deployment Steps
S3 bucket whose name matches the one in `/backend.tf` (currently set to `tf-state-group3-project`) that has *blocked* all public access must have already been created to persist the Terraform state. If the current name is taken, `backend.tf` must be modified to match.

The resource for our image storage bucket: `aws_s3_bucket.image_storage` in `/main.tf`, must have a unique name. If `tf-image-group3-project` is taken, the bucket property must be changed to something else.

A key pair named `group3admin` must have already been created. The private key .pem file must have its permissions set to readonly in order to ssh into the Bastion hosts.

# Post-Deployment
## Webserver Access
Must have copied the `group3admin` private key file into the Bastion host in order to access the webservers in its VPC using ssh or http.

Adding a security group rule enabling public ssh into `VPC-Dev-Bastion` is the quickest way to access the machines in the `VPC-Dev`. In practice, this would not be suitable for a dev environment.

## VPC Peering Communication
### Route Table Updates
The route table named `RT-Peer-to-Requester-SN` must be associated to `VPC-Shared-Private_SN2` and `RT-Peer-to-Accepter-SN` must be associated to `VPC-Dev-Private_SN1`.

### Security Group Updates
The security group named `VPC-PCX-Shared-VM-SG` must be added to `VPC-Shared-VM2` and `VPC-PCX-Dev-VM-SG` must be added to `VPC-Dev-VM1`.

`VPC-Shared-VM2` and `VPC-Dev-VM1` should now be able to ping each other.

## Copying from S3
Run this command to permit an EC2 instance to copy a file from an S3 bucket:
`aws ec2 associate-iam-instance-profile --iam-instance-profile Name=LabInstanceProfile --instance-id <instance_id>`

Upload `/images/mountain.jpeg` to the image storage bucket mentioned above.

From your instance, run `aws s3 cp s3://tf-image-group3-project/mountain.jpeg /home/ec2-user` to download the image. Make sure the name after `s3://` matches your S3 bucket.