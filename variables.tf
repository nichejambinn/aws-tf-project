variable "default_tags" {
  default = {

    Environment = "Test"
    Owner       = "Group3"
    Project     = "SYST35144_FinalProject"

  }
  description = "Default Tags for SYST35144_FinalProject"
  type        = map(string)
}
