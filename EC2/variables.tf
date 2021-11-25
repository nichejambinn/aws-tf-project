variable "vpc_id" { type = string }
variable "private_subnets" { type = list(any) }
variable "public_subnets" { type = list(any) }

variable "vpc_env" { 
    default = "Test"
    type = string 
}

variable "default_tags" {
  default = {

    Environment = "Test"
    Owner       = "Group3"
    Project     = "SYST35144_FinalProject"

  }
  description = "Default Tags for Instances"
  type        = map(string)
}
