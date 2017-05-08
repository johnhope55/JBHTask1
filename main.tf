provider "aws" {
region="eu-west-2"}

#Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "JBHVPC"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags      { Name = "JBHVPC" }
  lifecycle { create_before_destroy = true }
}

#Crrate Security Group
resource "aws_security_group" "web" {
  name = "JBH-firewall"
  description = "Firewall rules for server."

  ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

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


# Create Subnets

data "aws_subnet" "selected" {
  id = "JBHSubnet1"
}

resource "aws_security_group" "web" {
  vpc_id = "JBH-Firewall"

  ingress {
    cidr_blocks = ["${data.aws_subnet.selected.cidr_block}"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}

data "aws_subnet" "selected" {
  id = "JBHSubnet2"
}

resource "aws_security_group" "web" {
  vpc_id = "JBH-Firewall"

  ingress {
    cidr_blocks = ["${data.aws_subnet.selected.cidr_block}"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}


#Web Instances

resource "aws_instance" "web" {

  vpc_security_group_ids = [
    "${aws_security_group.web.id}"
  ]

  key_name="JohnsKey"

  ami = "ami-f1d7c395"
  instance_type = "t2.micro"
  tags {
    Name = "Johns-web-server1"
  }

  connection {
    user        = "ubuntu"
    private_key = "${file("JohnsKey.pem")}"
  }
  provisioner "file" {
	source="/GitFolder/WhichServerApp.jar"
	destination="/tmp/WhichServerApp.jar"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/WhichServerApp.jar",
      "/tmp/WhichServerApp.jar"
    ]
  } 
}

resource "aws_instance" "web" {

  vpc_security_group_ids = [
    "${aws_security_group.web.id}"
  ]

  key_name="JohnsKey"

  ami = "ami-f1d7c395"
  instance_type = "t2.micro"
  tags {
    Name = "Johns-web-server2"
  }

  connection {
    user        = "ubuntu"
    private_key = "${file("JohnsKey.pem")}"
  }


  provisioner "file" {
	source="/GitFolder/WhichServerApp.jar"
	destination="/tmp/WhichServerApp.jar"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod u+x /tmp/WhichServerApp.jar",
      "/tmp/WhichServerApp.jar"
    ]
  }  

}


# Create a new load balancer

resource "aws_elb" "JBHelb" {
  name               = "JBH-elb"
  availability_zones = ["eu-west-2"]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  instances                   = ["${aws_instance.foo.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "JBH-elb"
  }
}
