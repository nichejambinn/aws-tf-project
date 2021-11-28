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

# create VPC-Shared and subnets
module "networking_VPC_Shared" {
  source        = "./VPC"
  vpc_env       = "Shared"
  vpc_cidr      = "10.0.0.0/16"
  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  counter       = 2
}

# add Bastion host and webservers to VPC-Shared
module "servers_VPC_Shared" {
  source          = "./EC2"
  vpc_env         = "Shared"
  vpc_id          = module.networking_VPC_Shared.vpc_id
  public_subnets  = module.networking_VPC_Shared.public_subnets
  private_subnets = module.networking_VPC_Shared.private_subnets
  counter         = 2
}

# create VPC-Dev and subnets
module "networking_VPC_Dev" {
  source        = "./VPC"
  vpc_env       = "Dev"
  vpc_cidr      = "192.168.0.0/16"
  public_cidrs  = ["192.168.1.0/24", "192.168.2.0/24"]
  private_cidrs = ["192.168.3.0/24", "192.168.4.0/24"]
  counter       = 2
}

# add Bastion host and webservers to VPC-Dev
module "servers_VPC_Shared" {
  source          = "./EC2"
  vpc_env         = "Dev"
  vpc_id          = module.networking_VPC_Dev.vpc_id
  public_subnets  = module.networking_VPC_Dev.public_subnets
  private_subnets = module.networking_VPC_Dev.private_subnets
  counter         = 2
}

# create Peering Connection between VPC-Shared and VPC-Dev
resource "aws_vpc_peering_connection" "vpc_cxn_shared_dev" {
  vpc_id      = module.networking_VPC_Shared.vpc_id # requester
  peer_vpc_id = module.networking_VPC_Dev.vpc_id    # accepter
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