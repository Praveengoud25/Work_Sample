#variable file
variable "region" {
  type    = string
  default = "us-east-1"
  description = "To which region we need to do changes or add the resources we will confrim here"
}
variable "access_key" {
  type = string
  default = "AKIA56L7RPYLBXN4YATT"
  description = "to login"
}
variable "secret_key" {
  type = string
  default = "lz4kGzC3T9+khvX6RKDQvx+iCxHUpA0NXAsPwpd5"
  description = "to login"
}
variable "number_of_instances" {
  type = number
  default = 1
  description = "when we need to bring up few machines at-a-time we can change the count here to that much"
}

variable "instance_name" {
  type    = string
  default = "project-iac"
  description = "the name machine will be taken from here"
}

variable "ami" {
  type        = string
  default = "ami-0aa7d40eeae50c9a9"
  description = "The id of the machine image (AMI) to use for the server."
}

variable "itype" {
  type    = string
  default = "t2.micro"
  description = "The EBS volume type is defined here ."
}

variable "pem_file" {
  type = string
  default = "test-vir"
  description = "key to login into ec2 instance"
}

variable "keyPath" {
   default = "./test-vir.pem"
}

variable "subnet" {
  type        = string
  default = "subnet-003fd9896f3147027"
  description = "The subnet id of the vpc to use for the server."
}

variable "securitygroupid" {
  type        = list(string)
  default = ["ssg-000a5e33f834e1969","sg-000a5e33f834e1969","sg-007f5b42cd9519592","sg-01de2f30fa98ecbe0","sg-f789de8c","sg-05d34759cc6ec9b59"]
  description = "The aws_security_group defined here "
}
variable "ingress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
          protocol = "tcp"
          from_port = 0
          to_port = 65535
          cidr_block = "0.0.0.0/0"
          description = "opens all ports for incoming"
        },
  
        {
          from_port   = 0
          to_port     = 65535
          protocol    = "udp"
          cidr_block  = "0.0.0.0/0"
          description = ""
        },  

        {
          from_port   = 8080
          to_port     = 8080
          from_port   = 23
          to_port     = 23
          from_port   = 443
          to_port     = 443
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "test"
        },
    ]
}