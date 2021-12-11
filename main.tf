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

# create updated route tables to include peered networks
# these will be manually associated with their respective subnets
resource "aws_route_table" "rt-peer-to-accepter-sn" {
  vpc_id = module.networking["Dev"].vpc_id
  route {
    cidr_block                = local.vpc_envs["Shared"].private_cidrs[1]
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_cxn_shared_dev.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.networking["Dev"].vpc_nat_id
  }

  tags = merge(
    var.default_tags,
    {
      Name        = "RT-Peer-to-Accepter-SN"
      Environment = "Dev"
    }
  )
}

resource "aws_route_table" "rt-peer-to-requester-sn" {
  vpc_id = module.networking["Shared"].vpc_id
  route {
    cidr_block                = local.vpc_envs["Dev"].private_cidrs[0]
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_cxn_shared_dev.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.networking["Shared"].vpc_nat_id
  }

  tags = merge(
    var.default_tags,
    {
      Name        = "RT-Peer-to-Requester-SN"
      Environment = "Shared"
    }
  )
}

# create SGs such that VM-Shared-2 and VM-Dev-1 can ping each other
# these will be manually attached to their respective instances
resource "aws_security_group" "pcx_vm_sg" {
  for_each = local.vpc_envs

  name        = "VPC-PCX-${each.key}-VM-SG"
  description = "VPC Peering Connection ${each.key}-VM SG"
  vpc_id      = module.networking[each.key].vpc_id

  ingress = []

  egress = [
    {
      description = "all outbound is permitted"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = null
    }
  ]

  tags = merge(
    var.default_tags,
    {
      Name = "VPC-PCX-${each.key}-VM-SG"
      Environment = "${each.key}"
    }
  )
}

# enable ping
resource "aws_security_group_rule" "ping_pcx" {
  for_each = local.vpc_envs

  security_group_id = aws_security_group.pcx_vm_sg[each.key].id
  type = "ingress"
  description = "private ping between instances"
  from_port = -1
  to_port = -1
  protocol = "icmp"
  source_security_group_id = aws_security_group.pcx_vm_sg[each.key == "Shared" ? "Dev" : "Shared"].id
}

# create S3 bucket for image storage
resource "aws_s3_bucket" "image_bucket" {
  bucket = "tf-image-group3-project"
  acl    = "private"

  tags = merge(
    var.default_tags,
    {
      Name        = "S3-Bucket-Image-Storage"
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
