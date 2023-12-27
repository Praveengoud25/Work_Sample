provider "aws" {
  region = var.region
  profile = var.profile
}
#created a aws_security_group 
resource "aws_security_group" "project-iac-sg" {
  name = var.secgroupname
  vpc_id = var.vpc
  // To Allow SSH Transport
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = var.cidr_blocks
  }

  // To Allow Port 80 Transport
  ingress {
    from_port = 80
    protocol = ""
    to_port = 80
    cidr_blocks = var.cidr_blocks
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = var.cidr_blocks
  }
}

resource "aws_instance" "terraform_ec2"  {
  associate_public_ip_address = false
  count = var.number_of_instances
  ami = var.ami
  instance_type = var.itype
  subnet_id = var.subnet
  vpc_security_group_ids = [aws_security_group.project-iac-sg.id]
  
    root_block_device {
    delete_on_termination = true
    iops = 150
    volume_size = 50
    volume_type = "gp2"
  }
  tags = {
    Name ="SERVER01"
    Environment = "DEV"
    OS = "AL2"
    Managed = "IAC"
  }
  connection {
    type = "ssh"
    user = "ec2-user"
    host = self.private_ip
  }
  provisioner "remote-exec" {
      inline = ["sudo yum install git -y", "sudo yum install httpd -y"]
  }
}