# Setup our aws provider
variable "region" {
  default = "us-east-1"
}
provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "newsdgshygdf436dg-terraform-infra-na"
    region = "us-east-1"
    dynamodb_table = "newsdgshygdf436dg-terraform-locks"
    key = "news/terraform.tfstate"
  }
}
