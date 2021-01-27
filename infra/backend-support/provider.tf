# Setup our aws provider
variable "region" {
  default = "eu-west-1"
}

provider "aws" {
  region = var.region
}
