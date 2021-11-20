variable "vpc_cidr" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "counter" {
  type = number
  default = 1
  description = "Number of public and private subnets"
}

variable "public_cidrs" {
  type = list(any)
}

variable "private_cidrs" {
  type = list(any)
}

variable "environment_name" {
  type = string
}

variable "default_tags" {
  default = {
    Owner = "Group3"
    Project = "Group3FinalProject"
  }
  description = "Default Tags for VPCs"
  type = map(string)
}
