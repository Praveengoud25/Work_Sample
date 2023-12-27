provider "aws" {
  region = var.region
  profile = var.profile
}
resource "aws_launch_template" "user-data" {
    name = "user-data-test"
    description = "to test user data process"
    image_id = var.ami
    instance_type = var.itype
    key_name = var.key_pairname
    # Block device mappings for the instance
    block_device_mappings {
      device_name = "/dev/sda1"
      ebs {
        # Size of the EBS volume in GB
        volume_size = 20
        # Type of EBS volume (General Purpose SSD in this case)
        volume_type = "gp2"
      }
    }
    associate_public_ip_address = false
    subnet = va.subnet
    security_groups = var.securitygroupid
    iam_instance_profile = "arn:aws:iam::011821064023:instance-profile/emr_maintenance_dev_green"
  # Tag specifications for the instance
    tag_specifications {
    # Specifies the resource type as "instance"
      resource_type = "instance"

    # Tags to apply to the instance
      tags = {
        Name = "first template"
    }
  }
    user_data = "$path_of_user_data"
}