# Copyright 2016 Medallia Inc. All rights reserved
# Use of this source code is governed by the Apache 2.0
# license that can be found in the LICENSE file.

resource "aws_instance" "controllers" {

  depends_on = ["aws_route.jinn_vpc_egress_route", "aws_instance.cephnodes"]

  #Number of controllers we want in our system
  count = "${length(var.controllers)}"

  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    agent = false
    # The connection will use the local SSH agent for authentication.
    private_key = "${file("/Users/jcmartin/Workspaces/medallia/aws/jc-fabric-key.pem")}"
  }

  #Todo(Darshan): change vm sizes based on certain dynamics
  # NOTE: not all flavors are compatible with our HVM AMI.
  instance_type = "t2.medium"

  source_dest_check = "false"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${lookup(var.aws_amis, var.region)}"

  # The name of our SSH keypair we created above.
  key_name = "jc-fabric-key"

  user_data = "${element(template_cloudinit_config.controllersconfig.*.rendered, count.index)}"

  # This is basically equal distribution of resources. picking a region at index nodecount % azcount with each run. N%M = N - ((N/M)*M)
  subnet_id = "${element(aws_subnet.jinn_subnet.*.id, count.index - ((count.index / length(var.subnets) * length(var.subnets))))}"

  private_ip = "${element(var.controllers, count.index)}"

  vpc_security_group_ids = [ "${aws_security_group.jinn.id}" ]

  root_block_device {
    volume_size = 20
  }

  tags {
      "Name" = "jinn-${var.clustername}-controller${count.index}"
  }

  provisioner "file" {
    source = "../scripts"
    destination = "/home/ubuntu"
  }
  provisioner "file" {
    source = "plenum.deb"
    destination = "/home/ubuntu/plenum.deb"
  }
  provisioner "remote-exec" {
    inline = ["sudo bash -x /home/ubuntu/scripts/bootstrap.sh"]
  }
  provisioner "remote-exec" {
    inline = ["sudo reboot"]
  }
}

resource "template_file" "controllers_bootstrap_payload" {
  count    = "${length(var.controllers)}"
  template = "${file("bootstrap_payload.tpl")}"
  vars {
    nodes="${join(" ", var.nodes)}"
    controllers="${join(" ", var.controllers)}"
    cephnodes="${join(" ", var.cephnodes)}"
    roles="${join(" ", var.controller_roles)}"
    azSubnet="${join(",", aws_subnet.jinn_subnet.*.cidr_block)}"
    quaggaCidr="${var.quagga_cidr_block}"
    vpcCidr="${var.vpc_cidr_block}"
    clusterName="${var.clustername}"
    dcname="jinn"
    netip="${element(var.controllers,count.index)}"
    quorum="${var.quorum}"
  }

}

resource "template_cloudinit_config" "controllersconfig" {
  gzip = true
  base64_encode = true
  count = "${length(var.controllers)}"
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = "${element(template_file.controllers_bootstrap_payload.*.rendered, count.index)}"
  }
}

