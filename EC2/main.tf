data "aws_ami" "ami-amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Bastion host security group
resource "aws_security_group" "bastion_sg" {
  name        = "VPC-${var.vpc_env}-Bastion-SG"
  description = "Bastion Security Group"
  vpc_id      = var.vpc_id

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
      Name = "VPC-${var.vpc_env}-Bastion-SG"
      Environment = "${var.vpc_env}"
    }
  )
}

# public ssh ingress to Bastion only in Shared env
resource "aws_security_group_rule" "ssh_public" {
  security_group_id = aws_security_group.bastion_sg.id
  count = (var.vpc_env == "Shared") ? 1 : 0
  type = "ingress"
  description = "ssh access to Bastion from the internet"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
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
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
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
resource "aws_security_group" "webserver_sg" {
  name        = "VPC-${var.vpc_env}-Webserver-SG"
  description = "Webserver Security Group"
  vpc_id      = var.vpc_id

  ingress = [
    {
      description = "ssh access to webserver from the Bastion"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      security_groups = [aws_security_group.bastion_sg.id]
      cidr_blocks = []
      prefix_list_ids = []
      ipv6_cidr_blocks = []
      self = null
    },
    {
      description = "http access to webserver from the Bastion"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      security_groups = [aws_security_group.bastion_sg.id]
      cidr_blocks = []
      prefix_list_ids = []
      ipv6_cidr_blocks = []
      self = null
    }
  ]

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
      Name = "VPC-${var.vpc_env}-Webserver-SG"
      Environment = "${var.vpc_env}"
    }
  )
}

# webservers can ping each other
resource "aws_security_group_rule" "ping_private" {
  security_group_id = aws_security_group.webserver_sg.id
  type = "ingress"
  description = "private ping between webservers"
  from_port = -1
  to_port = -1
  protocol = "icmp"
  source_security_group_id = aws_security_group.webserver_sg.id
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
  vpc_security_group_ids      = [aws_security_group.webserver_sg.id]
  subnet_id                   = var.private_subnets[count.index].id
  user_data                   = file("install_apache.sh")
  
  tags = merge(
    var.default_tags,
    {
      Name = "VPC-${var.vpc_env}-VM${count.index + 1}"
      Environment = "${var.vpc_env}"
    }
  )
}