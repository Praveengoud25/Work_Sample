variable "number_of_instances" {
  type = number
  default = 1
  description = "when we need to bring up few machines at-a-time we can change the count here to that much"
}

variable "region" {
  type    = string
  default = "us-west-2"
  description = "To which region we need to do changes or add the resources we will confrim here"
}

variable "instance_name" {
  type    = string
  default = "project-iac"
  description = "the name machine will be taken from here"
}

variable "vpc" {
  type    = string
  default = "vpc-5234832d"
  description = "the vpc id which the machine needs to be brought up given here"
}

variable "ami" {
  type        = string
  default = "ami-08e2d37b6a0129927"
  description = "The id of the machine image (AMI) to use for the server."
}

variable "itype" {
  type        = string
  default = "t3.micro"
  description = "The EBS volume type is defined here ."
}

variable "subnet" {
  type        = string
  default = "subnet-0546d662"
  description = "The subnet id of the vpc to use for the server."
}

variable "secgroupname" {
  type        = string
  default = "ansible-controller"
  description = "The aws_security_group defined here "
}

variable "profile" {
  type        = string
  default = "011821064023_mnd-l3-support-role"
  description = "the profile name defined here which helps in authentication to aws "
}

variable "cidr_blocks" {
  type        = list
  default = ["0.0.0.0/0"]
  description = "this defines the range "
}