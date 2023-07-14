# This file contains all the terraform variables contained in this project

variable "base_cidr_block" {
  description = "A /16 CIDR range definition, such as 10.0.0.0/16, that the VPC will use"
  type = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Denotes the name of the VPC wherever specified"
  type = string
  default = "main-web_app-vpc"
}

variable "internet_gw" {
  type        = string
  description = "Name of your internet gateway"
  default     = "main-web_app-igw"
}

variable "availability_zones" {
  description = "A list of availability zones in which to create subnets"
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]  # Replace with your desired AZs
}