variable "vpc_id" { type = string }
variable "cidr_block" { type = string }
variable "subnet_name" { type = string }
variable "availability_zone" { type = string }
variable "environment_tag" { type = string }

variable "is_private" {
  default = false
  type = bool
}

variable "default_tags" {
  default = {
    Owner = "Group3"
    Project = "SYST35144_FinalProject"
  }
  type = map(string)
}
