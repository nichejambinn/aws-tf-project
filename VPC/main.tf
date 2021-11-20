#------VPC------
resource "aws_vpc" var.vpc_name {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = map(var.default_tags, var.environment_name)
}

#------Internet Gateway------
resource "aws_igw" join("_", [var.vpc_name, "igw"]) {
  vpc_id = aws_vpc.vpc-tf.id
  tags = map(var.default_tags, var.environment_name)
}

#------Routing Table------
# TODO: Attach public routing table
# TODO: Configure Default Route for routing table
# TODO: Add Tags to routing table
