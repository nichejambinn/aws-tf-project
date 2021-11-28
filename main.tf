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

# create VPC and subnets for each environments
module "networking" {
  for_each = local.vpc_envs

  source = "./VPC"
  vpc_env = each.key
  vpc_cidr = local.vpc_cidrs[each.key]
  public_cidrs = local.public_cidrs[each.key]
  private_cidrs = local.private_cidrs[each.key]
  counter = length(local.public_cidrs[each.key])
}

# add webservers and bastion host to each VPC 
module "servers" {
  for_each = local.vpc_envs

  source = "./EC2"
  vpc_env = each.key
  vpc_id = module.networking[each.key].vpc_id
  public_subnets = module.networking[each.key].public_subnets
  private_subnets = module.networking[each.key].private_subnets
  counter = length(module.networking[each.key].public_subnets)
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
