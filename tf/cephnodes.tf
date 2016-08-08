# Copyright 2016 Medallia Inc. All rights reserved
# Use of this source code is governed by the Apache 2.0
# license that can be found in the LICENSE file.

resource "aws_instance" "cephnodes" {
  #Number of controllers we want in our system
  count = "${length(var.cephnodes)}"

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

  user_data = "${data.template_cloudinit_config.cephconfig.rendered}"

  # This is basically equal distribution of resources. picking a region at index nodecount % azcount with each run. N%M = N - ((N/M)*M)
  subnet_id = "${element(aws_subnet.jinn_subnet.*.id, count.index - ((count.index / length(var.subnets) * length(var.subnets))))}"

  private_ip = "${element(var.cephnodes, count.index)}"

  vpc_security_group_ids = [ "${aws_security_group.jinn.id}" ]

  ebs_optimized = true
  root_block_device {
    volume_size = 20
  }
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 30
    delete_on_termination = true
  }
  ebs_block_device {
    device_name = "/dev/sdc"
    volume_size = 30
    delete_on_termination = true
  }
  ebs_block_device {
    device_name = "/dev/sdd"
    volume_size = 30
    delete_on_termination = true
  }
  tags {
      "Name" = "jinn-${var.clustername}-ceph${count.index}"
  }
  provisioner "file" {
    source = "../scripts"
    destination = "/home/ubuntu"
  }

  #provisioner "remote-exec" {
  #  inline = ["sudo bash -x /home/ubuntu/scripts/bootstrap.sh"]
  #}
}

data "template_file" "cephnodes_bootstrap_payload" {
  template = "${file("bootstrap_payload.tpl")}"
  vars {
    controllers="${join(" ", var.controllers)}"
    nodes="${join(" ", var.nodes)}"
    cephnodes="${join(" ", var.cephnodes)}"
    roles="${join(" ", var.ceph_roles)}"
    azSubnet="${join(",", aws_subnet.jinn_subnet.*.cidr_block)}"
    quaggaCidr="${var.quagga_cidr_block}"
    vpcCidr="${var.vpc_cidr_block}"
    clusterName="${var.clustername}"
    dcname="jinn"
    count="${count.index}"
    netip="${element(var.cephnodes, count.index)}"
    quorum="${var.quorum}"
  }



}

data "template_cloudinit_config" "cephconfig" {
  gzip = true
  base64_encode = true

  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = "${data.template_file.cephnodes_bootstrap_payload.rendered}"
  }
}

