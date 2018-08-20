variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080 // If you don't define it at apply, this will be used.
}

// This value will be provided to you after terraform apply completes
output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}