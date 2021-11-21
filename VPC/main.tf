#------VPC------
resource "aws_vpc" "vpc-shared" {
  cidr_block = var.vpc-shared_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = map(
    var.default_tags, 
    {
      Environment = var.vpc-shared_environment_name
    }
  )
}

# Attach Internet Gateway to VPC-Shared
resource "aws_igw" "vpc-shared_igw"{
  vpc_id = aws_vpc.vpc-shared.id
  tags = map(
    var.default_tags
  )
}

#Define subnets for VPC-Shared
module "subnet" {
  source = "../Subnet"
  for_each = {
    Public_SN1  = {
      cidr = "10.0.1.0/24"
      is_private = false
      availability_zone = "us-east-1a"}
    Public_SN2  = {
      cidr = "10.0.2.0/24",
      is_private = false
      availability_zone = "us-east-1a"}
    Private_SN1 = {
      cidr = "10.0.3.0/24" 
      is_private = true
      availability_zone = "us-east-1b"}
    Private_SN2 = {
      cidr = "10.0.4.0/24" 
      is_private = true
      availability_zone = "us-east-1b"}
  }
  vpc_id = aws_vpc.vpc-shared.id
  subnet_name = each.key
  availability_zone = each.value.availability_zone
  cidr_block = each.value.cidr
  is_private = each.value.is_private
  environment_tag = var.vpc-shared_environment_name
}

# Define VPC Dev
resource "aws_vpc" "vpc-dev" {
  cidr_block = var.vpc-dev_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = map(
    var.default_tags,
    {
      Environment = var.vpc-dev_environment_name
    }
  )
}

# Attach Internet Gateway to VPC-Dev
resource "aws_igw" "vpc-dev_igw"{
  vpc_id = aws_vpc.vpc-dev.id
  tags = map(
    var.default_tags
  )
}

# Define subnets for VPC-Dev
module "subnet" {
  source = "../Subnet"
  for_each = {
    Public_SN1 = {
      cidr = "192.168.1.0/24"
      is_private = false
      availability_zone = "us-east-1a"
    }
    Public_SN2 = {
      cidr = "192.168.2.0/24"
      is_private = false
      availability_zone = "us-east-1b"
    }
    Private_SN1 = {
      cidr = "192.168.3.0/24"
      is_private = true 
      availability_zone = "us-east-1a"
    }
    Private_SN2 = {
      cidr = "192.168.4.0/24"
      is_private = true 
      availability_zone = "us-east-1b"
    }
  }
  vpc_id = aws_vpc.vpc-dev.id
  subnet_name = each.key
  availability_zone = each.value.availability_zone
  cidr_block = each.value.cidr
  is_private = each.value.is_private
  environment_tag = var.vpc-dev_environment_name
}

#------Routing Table------
# TODO: Attach public routing table
# TODO: Configure Default Route for routing table
# TODO: Add Tags to routing table
