#******************
#** Generic Vars **
#******************
variable "env" {
  type = string
}

variable "contact" {
  type = string
}

variable "project" {
  type = string
}

#*******************
#** Specific Vars **
#*******************
variable "vpc_id" {
  type = string
}

variable "instance_type" {
  type = string
}