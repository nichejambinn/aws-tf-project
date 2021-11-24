variable "vpc_id" { type = string }
variable "public_subnet_id" { type = string }

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
