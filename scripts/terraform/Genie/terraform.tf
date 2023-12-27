provider "aws" {
  region = var.region
  profile = var.profile
}
resource "aws_launch_template" "user-data" {
    name = "503309564-Praveen-userdata-Rhel"
    id = "lt-09c8b45d4c61f4f37s"

}