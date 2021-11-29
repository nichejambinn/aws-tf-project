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
# !?! see ??? below "the route tables should only allow permitted ping"

# TODO: update Shared Bastion host SG to ssh into Dev

# TODO: create SG where VM-Shared-2 and VM-Dev-1 can ping each other
# ??? this is only a 'partial soln'

# TODO: create S3 bucket and store an image in it

# TODO: create an IAM role to access the bucket

# TODO: attach the IAM role to VM-Shared-1