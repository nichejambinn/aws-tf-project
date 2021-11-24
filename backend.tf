terraform {
  backend "s3" {
    bucket = "tf-state-group3-project"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
