variable "file_hash" {}
variable "bucket_name" {}
variable "bucket_key" {}
variable "function_name" {}
variable "handler" {}

variable "runtime" {
  default = "java8"
}

variable "timeout" {
  default = 30
}

variable "memory" {
  default = 1024
}

variable "api_gateway_arn" {}

variable "retention_in_days" {
  default = 7
}