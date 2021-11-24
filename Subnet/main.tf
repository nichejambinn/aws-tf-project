# Private Subnet Creation
resource "aws_subnet" "private" {
  count = var.is_private ? 1 : 0
  vpc_id = var.vpc_id
  availability_zone = var.availability_zone
  cidr_block = var.cidr_block

  tags = merge(
    var.default_tags,
    {
      Environment = var.environment_tag
    }
  )
}

resource "aws_subnet" "public" {
  count = var.is_private ? 0 : 1
  vpc_id = var.vpc_id
  availability_zone = var.availability_zone
  cidr_block = var.cidr_block

  tags = merge(
    var.default_tags,
    {
      Environment = var.environment_tag
    }
  )
}

