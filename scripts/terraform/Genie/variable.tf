variable "region" {
  type    = string
  default = "us-west-2"
  description = "To which region we need to do changes or add the resources we will confrim here"
}

variable "vpc" {
  type    = string
  default = "vpc-5234832d"
  description = "the vpc id which the machine needs to be brought up given here"
}

variable "ami" {
  type        = string
  default = "ami-0e79a841aadaba0a0"
  description = "The id of the machine image (AMI) to use for the server."
}

variable "itype" {
  type        = string
  default = "t2.micro"
  description = "The EBS volume type is defined here ."
}

variable "key_pairname" {
  type        = string
  default = "503340174-harish-test-dev-pwr-ssm"
  description = "The EBS volume type is defined here ."
}


variable "subnet" {
  type        = string
  default = "subnet-0860ca41"
  description = "The subnet id of the vpc to use for the server."
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
 
variable "genie_launch_config" {
  type = string
  default = "usw02-dev-pwr-genie-as-b-asg-launch-configuration-20230508184914471700000002"
  description = "this defines the ASG Launch tempate name"
}

variable "genie_asg" {
  type = string
  default = "usw02-dev-pwr-genie-as-b-asg"
  description = "this defines the asg name"
}
variable "securitygroupid" {
  type        = list(string)
  default = ["ssg-000a5e33f834e1969","sg-000a5e33f834e1969","sg-007f5b42cd9519592","sg-01de2f30fa98ecbe0","sg-f789de8c","sg-05d34759cc6ec9b59"]
  description = "The aws_security_group defined here "
}