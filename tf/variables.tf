# Copyright 2016 Medallia Inc. All rights reserved
# Use of this source code is governed by the Apache 2.0
# license that can be found in the LICENSE file.


variable "clustername"{
  default = "jinn"
}

variable "region" {
  description = "AWS region to launch servers."
}

variable "azs" {
    default = {
        "us-west-1" = "us-west-1b"
        "us-west-2" = "us-west-2a"
        "us-east-1" = "us-east-1d"
        "eu-west-1" = "eu-west-1a"
        "sa-east-1" = "sa-east-1a"
        "ap-southeast-1" = "ap-southeast-1a"
        # use "aws ec2 describe-availability-zones --region us-west-2"
        # to figure out the name of the AZs on every region
    }
}

# Ubuntu Precise 12.04 LTS (x64)
variable "aws_amis" {
  default = {
    us-west-1 = "ami-79d19619"
    us-west-2 = "ami-9caa53fc"
    us-east-1 = "ami-0ce5611b"
    eu-west-1 = "ami-4f56c53c"
    ap-southeast-1 = "ami-6ef8250d"
    sa-east-1 = "ami-7ecd5912"
  }
}

variable "vpc_cidr_block" {
    description = "Desired /16 block for the cluster"
    default = "10.113.0.0/16"
}

variable "quagga_cidr_block" {
    description = "Desired /16 block for the containers in the cluster"
    default = "10.121.0.0/16"
}

variable "controllers"{
    type="list"
    description = "list of controllers"
}

variable "controller_roles"{
    type = "list"
    description = "roles for controllers"
}

variable "quorum"{
    description = "quorum"
}

variable "nodes"{
    type = "list"
    description = "list of nodes"
}

variable "node_roles"{
    type = "list"
    description = "roles for nodes"
}

variable "cephnodes"{
    type = "list"
    description = "list of ceph nodes"
}

variable "ceph_roles"{
    type = "list"
    description = "roles for ceph nodes"
}

variable "subnets"{
    type = "list"
    description = "list of subnets"
}