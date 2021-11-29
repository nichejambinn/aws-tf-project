locals {
  vpc_envs = {
    Shared : {
      vpc_cidr      = "10.0.0.0/16"
      public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
      private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
    },

    Dev : {
      vpc_cidr      = "192.168.0.0/16"
      public_cidrs  = ["192.168.1.0/24", "192.168.2.0/24"]
      private_cidrs = ["192.168.3.0/24", "192.168.4.0/24"]
    }
  }
}

variable "default_tags" {
  default = {

    Environment = "Test"
    Owner       = "Group3"
    Project     = "SYST35144_FinalProject"

  }
  description = "Default Tags for SYST35144_FinalProject"
  type        = map(string)
}
