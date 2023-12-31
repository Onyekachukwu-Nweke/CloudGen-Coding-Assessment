# This file contains all the terraform variables contained in this project

variable "base_cidr_block" {
  description = "A /16 CIDR range definition, such as 10.0.0.0/16, that the VPC will use"
  type = string
  default     = "10.0.0.0/16"
}

variable "aws_region" {
  type = string
  description = "This defines the deployment region"
  default     = "us-east-1"
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "vpc_name" {
  description = "Denotes the name of the VPC wherever specified"
  type = string
  default = "main-cloudgen-vpc"
}

variable "internet_gw" {
  type        = string
  description = "Name of your internet gateway"
  default     = "main-cloudgen-igw"
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
    # key_name      = string
    volume_size   = number
    device_name   = string
  })

  default = {
    image_id      = "ami-053b0d53c279acc90"
    instance_type = "t2.micro"
    # key_name      = "cloudgen-1"
    volume_size   = 20
    device_name   = "/dev/xvda"
  }
}

variable "tag_count" {
  description = "Number of tags"
  default     = 2
}

variable "inbound_ports" {
  description = "Ports to open for ingress"
  type    = list(number)
  default = [80, 443, 22]
}

variable "database_name" {
  description = "Value of the database name"
  type        = string
  default     = "cloudgento_webapp"
}

variable "database_user" {
  description = "Value of the database user"
  type        = string
  default     = "admin"
}

variable "database_password" {
  description = "Value of the database password"
  type        = string
  default     = "cloudgento2022"
}