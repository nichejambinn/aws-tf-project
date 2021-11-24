# AZ data source
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "vpc-tf" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}"
      Environment = "${var.vpc_env}"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc-tf.id
  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-IGW"
      Environment = "${var.vpc_env}"
    }
  )
}

# private subnets
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.vpc-tf.id
  count             = var.counter
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_cidrs[count.index]

  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-Private_SN${count.index + 1}"
      Environment = "${var.vpc_env}"
    }
  )
}

# public subnets
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc-tf.id
  count             = var.counter
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.public_cidrs[count.index]

  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-Public_SN${count.index + 1}"
      Environment = "${var.vpc_env}"
    }
  )
}

# Elastic IP
resource "aws_eip" "nat-eip" {
  vpc = true
}

# NAT GW
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public[1].id

  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-NAT-GW"
      Environment = "${var.vpc_env}"
    }
  )
}

# public route table
resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.vpc-tf.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-Public_RT"
      Environment = "${var.vpc_env}"
    }
  )
}

# private route table 
resource "aws_route_table" "rt-private" {
  vpc_id = aws_vpc.vpc-tf.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
  
  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-Private_RT"
      Environment = "${var.vpc_env}"
    }
  )
}

# associate route tables with subnets
resource "aws_route_table_association" "association-pub" {
  count          = var.counter
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.rt-public.id
}

resource "aws_route_table_association" "association-pr" {
  count          = var.counter
  subnet_id      = aws_subnet.private.*.id[count.index]
  route_table_id = aws_route_table.rt-private.id
}
