provider "aws" {
  profile = "mac-personal" // Grabs creds from .aws/credentials or /config, need to figure out which
  region = "us-east-1"
}

# General syntax for a Terraform resource:
# resource "PROVIDER_TYPE" "NAME" {
#   [CONFIG...]
# }

resource "aws_launch_configuration" "example" {
  image_id = "ami-40d28157"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p "${var.server_port}" &
    EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
  name = "terraform-asg-example"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb.id}"]

  // ELB needs a listener to route requests through...
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
    // ELB's security group must allow outbound requests for this to work.
  }
}

// EC2 -- to be replaced with a launch configuration resource
# resource "aws_instance" "example" {
#   ami = "ami-40d28157"
#   instance_type = "t2.micro"
#   // Computed/interpolated value for the security group ID
#   vpc_security_group_ids = ["${aws_security_group.instance.id}"]

#   tags {
#     # Add a name to appear in EC2 console
#     Name = "terraform-example"
#   }

  // For this to actually work (i.e. be accessible), we need a security group (below)
  // <<-EOF activates tf's multiline ezmode
  # user_data = <<-EOF
  #   #!/bin/bash
  #   echo "Hello, World" > index.html
  #   nohup busybox httpd -f -p "${var.server_port}" &
  #   EOF
    // end tf's multiline ezmode
# }

// Security Group for EC2 (now in an autoscaling group [ASG])
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    // "${var.VARIABLE_NAME}"
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Everywhere -- all possible IPs
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Security Group for the ELB...
resource "aws_security_group" "elb" {
  name = "terraform_example_elb"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}