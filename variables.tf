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

variable "server_info" {
  description = "Describes everything about the EC2 instance to be created"
  type = object({
    image_id      = string
    instance_type = string
    key_name      = string
    volume_size   = number
    device_name   = string
  })

  default = {
    image_id      = "ami-06878d265978313ca"
    instance_type = "t2.micro"
    key_name      = "cloudgen-1"
    volume_size   = 10
    device_name   = "/dev/xvda"
  }
}

variable "inbound_ports" {
  description = "Ports to open for ingress"
  type    = list(number)
  default = [80, 443]
}