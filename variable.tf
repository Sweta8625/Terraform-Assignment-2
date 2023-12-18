variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16" 
}

variable "tag_name" {
  description = "Name for the VPC"
  type        = string
  default     = "main"
}

variable "instance_ami" {
  description = "Amazon Machine Image (AMI) ID for the instance"
  type        = string
  default     = "ami-05c0f5389589545b7"
}
