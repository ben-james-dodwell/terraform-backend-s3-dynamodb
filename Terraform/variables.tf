variable "backend_bucket" {
    type = string
    default = "terraform-state"
}

variable "backend_dynamo_table" {
    type = string
    default = "terraform-state"
}