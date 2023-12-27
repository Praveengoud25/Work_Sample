provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

data "aws_s3_object" "user_data" {
  bucket = "install-scripts1"
  key = "install_script.sh"
}  

resource "aws_security_group_rule" "ingress_rules" {
  count = length(var.ingress_rules)
  type              = "ingress"
  security_group_id = "sg-041e18817f5cc6811"
  from_port         = var.ingress_rules[count.index].from_port
  to_port           = var.ingress_rules[count.index].to_port
  protocol          = var.ingress_rules[count.index].protocol
  cidr_blocks       = [var.ingress_rules[count.index].cidr_block]
  description       = var.ingress_rules[count.index].description
}

resource "aws_instance" "terraform_ec2"  {
  associate_public_ip_address     = true
  count                           = var.number_of_instances
  ami                             = var.ami
  instance_type                   = var.itype
  subnet_id                       = var.subnet
  security_groups                 = var.securitygroupid
  key_name                        = var.pem_file
  user_data                       = data.aws_s3_object.user_data.body
  iam_instance_profile            = "allows3"
    root_block_device {
    delete_on_termination = true
    #iops = 150
    volume_size = 50
    volume_type = "gp2"
  }
  tags = {
    Name ="SERVER01"
    Environment = "DEV"
    OS = "AL2"
    Managed = "IAC"
  }
# Login to the ec2-user with the aws key.
connection {
  type        = "ssh"
  user        = "ec2-user"
  private_key = file(var.keyPath)
  host        = self.public_ip
  }
}