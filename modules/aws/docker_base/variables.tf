#******************
#** Generic Vars **
#******************
variable "env" {
  type        = string
  description = "The environment tag to be used with the ec2 instance"
}

variable "contact" {
  type        = string
  description = "The contact tag to be used with the ec2 instance"
}

variable "project" {
  type        = string
  description = "The project tag to be used with the ec2 instance"
}

#*******************
#** Specific Vars **
#*******************
variable "vpc_id" {
  type        = string
  description = "The VPC ID for the EC2 instance to be deployed into"
}

variable "instance_type" {
  type        = string
  description = "The instance type of the EC2 instance"
}