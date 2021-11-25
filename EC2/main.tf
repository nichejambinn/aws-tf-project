# AZ data source
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ami-amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Bastion host security group
module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4"

  name        = "VPC-${var.vpc_env}-Bastion-SG"
  description = "Bastion Security Group"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "access to Bastion from the internet"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = [
    "all-all"
  ]

  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-Bastion-SG"
      Environment = "${var.vpc_env}"
    }
  )
}

# Bastion host instance
module "bastion_host" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name                        = "VPC-${var.vpc_env}-Bastion"
  ami                         = data.aws_ami.ami-amzn2.id
  instance_type               = "t2.micro"
  key_name                    = "group3admin"
  monitoring                  = true
  vpc_security_group_ids      = [module.bastion_sg.security_group_id]
  subnet_id                   = var.public_subnets[0].id
  associate_public_ip_address = true
  
  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-Bastion"
      Environment = "${var.vpc_env}"
    }
  )
}

# webserver security group
module "webserver_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4"

  name        = "VPC-${var.vpc_env}-Webserver-SG"
  description = "Webserver Security Group"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh access to webserver from the Bastion host"
      security_groups = [module.bastion_sg.id]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http access to webserver from the Bastion host"
      security_groups = [module.bastion_sg.id]
    }
  ]

  egress_rules = [
    "all-all"
  ]

  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-Webserver-SG"
      Environment = "${var.vpc_env}"
    }
  )
}

# webservers
module "webservers" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"
  count = var.counter

  name                        = "VPC-${var.vpc_env}-VM${count.index + 1}"
  ami                         = data.aws_ami.ami-amzn2.id
  instance_type               = "t2.micro"
  key_name                    = "group3admin"
  monitoring                  = true
  vpc_security_group_ids      = [module.webserver_sg.security_group_id]
  subnet_id                   = var.private_subnets[count.index].id
  user_data                   = file("user-data/install_apache.sh")
  
  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-VM${count.index + 1}"
      Environment = "${var.vpc_env}"
    }
  )
}