variable "backend_bucket" {
    type = string
    default = "terraform-state"
}

variable "backend_dynamo_table" {
    type = string
    default = "terraform-state"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "aws_account" {
  type    = string
  default = "############"
}