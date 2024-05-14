variable "backend_bucket" {
    type = string
    default = "terraform-state"
}

variable "dynamo_table" {
    type = string
    default = "terraform-state"
}