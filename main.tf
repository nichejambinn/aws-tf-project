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
resource "aws_route_table" "rt-peer-to-accepter-sn" {
  vpc_id = module.networking["Dev"].vpc_id
  route {
    cidr_block = local.vpc_envs["Shared"].private_cidrs[1]
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_cxn_shared_dev.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.networking["Dev"].vpc_nat_id
  }
  tags = merge(
    var.default_tags,
    {
      Name = "rt-peer-to-accpeter-sn"
      Environment = "Dev"
    }
  )
}

resource "aws_route_table" "rt-peer-to-requester-sn" {
  vpc_id = module.networking["Shared"].vpc_id
  route {
    cidr_block = local.vpc_envs["Dev"].private_cidrs[0]
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_cxn_shared_dev.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.networking["Shared"].vpc_nat_id
  }
  tags = merge(
    var.default_tags,
    {
      Name = "rt-peer-to-requester-sn"
      Environment = "Shared"
    }
  )
}

/*
resource "aws_route_table_association" "association-shared-to-dev-pr_sn1" {
  subnet_id = module.networking["Shared"].private_subnets[1].id
  route_table_id = aws_route_table.rt-peer-to-requester-sn.id
}

resource "aws_route_table_association" "association-dev-to-shared-pr_sn2" {
  subnet_id = module.networking["Dev"].private_subnets[0].id
  route_table_id = aws_route_table.rt-peer-to-accepter-sn.id
}
*/

# TODO: update Shared Bastion host SG to ssh into Dev

# TODO: create SG where VM-Shared-2 and VM-Dev-1 can ping each other
# ??? this is only a 'partial soln'

# create S3 bucket
resource "aws_s3_bucket" "image_bucket" {
  bucket = "tf-image-group3-project"
  acl    = "private"

  tags = merge(
    var.default_tags,
    {
      Name        = "Bucket-Image-Storage"
      Environment = "S3"
    }
  )
}

# upload image to the S3 bucket 
# resource "aws_s3_bucket_object" "mountain_image" {
#   bucket = aws_s3_bucket.image_bucket.id
#   key    = "profile"
#   acl    = "private"
#   source = "./images/mountain.jpeg"
#   etag   = filemd5("./images/mountain.jpeg")
# }
