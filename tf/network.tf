# Create a VPC to launch our instances into
resource "aws_vpc" "jinn_vpc" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags{
     "Name" = "${var.clustername}-jinn-${var.region}-vpc"
  }
}

# Create a subnet to launch our instances into
resource "aws_subnet" "jinn_subnet" {
  vpc_id            = "${aws_vpc.jinn_vpc.id}"
  count             = "${length(var.subnets)}"
  cidr_block        = "${element(var.subnets, count.index)}"
  availability_zone = "${element(split(",", lookup(var.azs, var.region)), count.index)}"
  map_public_ip_on_launch = true
  tags {
      "Name" =  "jinn-${var.clustername}-${element(split(",", lookup(var.azs, var.region)), count.index)}-sn"
  }
}

# Internet gateway for our VPC to latch on to
resource "aws_internet_gateway" "jinn_internet_gateway" {
    vpc_id = "${aws_vpc.jinn_vpc.id}"
    tags {
      "Name" = "jinn-${var.clustername}-${var.region}-igw"
    }
}

# An egress route for our VPC to talk to the internet
resource "aws_route" "jinn_vpc_egress_route" {
    route_table_id = "${aws_vpc.jinn_vpc.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.jinn_internet_gateway.id}"
}

resource "aws_security_group" "jinn" {
  name = "${var.clustername}-jinn-${var.region}-node-sg"
  description = "Ingress and egress rules for node/slave machines"
  vpc_id = "${aws_vpc.jinn_vpc.id}"

  # Add multiple ingress and egress rules as required
  ingress {
      from_port = 22
      to_port = 22
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      self = true
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}
