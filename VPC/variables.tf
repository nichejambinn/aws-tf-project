variable "vpc-shared_cidr" { type = string }
variable "vpc-dev_cidr" { type = string  }

variable "vpc-shared_environment_name" { type = string }
variable "vpc-dev_environment_name" { type = string }

variable "default_tags" {
  default = {
    Owner = "Group3"
    Project = "Group3FinalProject"
  }
  description = "Default Tags for VPCs"
  type = map(string)
}
