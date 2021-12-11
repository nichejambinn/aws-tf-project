terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.6"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# create VPC and subnets for each environment
module "networking" {
  for_each = local.vpc_envs

  source        = "./VPC"
  vpc_env       = each.key
  vpc_cidr      = each.value.vpc_cidr
  public_cidrs  = each.value.public_cidrs
  private_cidrs = each.value.private_cidrs
  counter       = length(each.value.public_cidrs)
}

# add webservers and bastion host to each VPC 
module "servers" {
  for_each = local.vpc_envs

  source          = "./EC2"
  vpc_env         = each.key
  vpc_id          = module.networking[each.key].vpc_id
  public_subnets  = module.networking[each.key].public_subnets
  private_subnets = module.networking[each.key].private_subnets
  counter         = length(module.networking[each.key].public_subnets)
}

# create Peering Connection between VPC-Shared and VPC-Dev
resource "aws_vpc_peering_connection" "vpc_cxn_shared_dev" {
  vpc_id      = module.networking["Shared"].vpc_id # requester
  peer_vpc_id = module.networking["Dev"].vpc_id    # accepter
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = merge(
    var.default_tags,
    {
      Name        = "VPC-Connection-Shared-Dev"
      Environment = "Shared-Dev"
    }
  )
}

# TODO: update route tables to include peered networks
# !?! see ??? and: "the route tables should not have rules that..." (doc)

# TODO: update Shared Bastion host SG to ssh into Dev

# TODO: create SG where VM-Shared-2 and VM-Dev-1 can ping each other
# ??? this is only a 'partial soln'

# create S3 bucket
resource "aws_s3_bucket" "final_project" {
  bucket = "final_project_bucket"
  acl    = "private"

  tags = {
    Name        = "Bucket_Final_Project"
    Environment = "Dev"
  }
}

# upload image to the s3 bucket 
resource "aws_s3_bucket_object" "image" {

  bucket = aws_s3_bucket.final_project.id
  key    = "profile"
  acl    = "private"
  source = "./images/mountain.jpeg"
  etag   = filemd5("./images/mountain.jpeg")
}

# TODO: create an IAM role to access the bucket
resource "aws_iam_policy" "final_project_access_bucket" {
  name   = "tf_access_bucket"
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement":[
      {
        "Action":[
          "s3:ListBucket"
        ],
        "Effect":"Allow",
        "Resource": "${aws_s3_bucket.final_project.arn}"
      },     
      {
        "Action":[
          "s3:GetObject"
        ],
        "Effect":"Allow",
        "Resource": "${aws_s3_bucket.final_project.arn}/*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "VM-Shared-1-role" {
  name = "VM-Shared-1-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          sevice = "ec2.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_policy_attachment" "VM-Shared-1-policy-role" {
  name       = "VM-Shared-1-attachment"
  roles      = [aws_iam_role.VM-Shared-1-role.name]
  policy_arn = aws_iam_policy.final_project_access_bucket.arn
}

resource "aws_iam_instance_profile" "VM-Shared-1-profile" {
  name = "VM-Shared-1-profile"
  role = aws_iam_role.VM-Shared-1-role.name
}
