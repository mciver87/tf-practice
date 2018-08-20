provider "aws" {
  profile = "mac-personal" // Grabs creds from .aws/credentials or /config, need to figure out which
  region = "us-east-1"
}

# General syntax for a Terraform resource:
# resource "PROVIDER_TYPE" "NAME" {
#   [CONFIG...]
# }

resource "aws_instance" "example" {
  ami = "ami-40d28157"
  instance_type = "t2.micro"

  tags {
    # Add a name to appear in EC2 console
    Name = "terraform-example"
  }
}

