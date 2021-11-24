terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.6"
}

provider "aws" {
  profile = "default"
  region = "us-east-1"
}

# create VPC-Dev and subnets
module "networking_VPC_Dev" {
  source = "./VPC"
  vpc_env = "Dev"
  vpc_cidr = "192.168.0.0/16"
  public_cidrs = ["192.168.1.0/24", "192.168.2.0/24"]
  private_cidrs = ["192.168.3.0/24", "192.168.4.0/24"]
  counter = 2
}

# add Bastion host to public subnet
module "bastion_VPC_Dev" {
  source = "./EC2"
  vpc_env = "Dev"
  vpc_id = module.networking_VPC_Dev.vpc_id
  public_subnet_id = module.networking_VPC_Dev.public_subnets[0].id
}

# create VPC-Shared and subnets
module "networking_VPC_Shared" {
  source = "./VPC"
  vpc_env = "Shared"
  vpc_cidr = "10.0.0.0/16"
  public_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
  counter = 2
}