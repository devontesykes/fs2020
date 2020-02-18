variable "ibmcloud_region" {
  description = "Preferred IBM Cloud region to use for your infrastructure"
  default = "us-south"
}

variable "vpc_name" {
  default = "vpc-fs2020-lab"
  description = "Name of your VPC"
}

variable "zone1" {
  default = "us-south-1"
  description = "Define the 1st zone of the region"
}

variable "zone2" {
  default = "us-south-2"
  description = "Define the 2nd zone of the region"
}

variable "zone3" {
  default = "us-south-3"
}

variable "zone1_cidr" {
  default = "172.16.1.0/24"
  description = "CIDR block to be used for zone 1"
}

variable "zone2_cidr" {
  default = "172.16.2.0/24"
  description = "CIDR block to be used for zone 2"
}

variable "zone3_cidr" {
  default = "172.16.3.0/24"
}

variable "ssh_public_key" {
  default = ""
  description = "SSH Public Key contents to be used"
}

variable "image" {
  default = "r006-14140f94-fcc4-11e9-96e7-a72723715315"
  description = "OS Image ID to be used for virtual instances"
}

variable "profile" {
  default = "cx2-2x4"
  description = "Instance profile to be used for virtual instances"
}

resource "ibm_is_vpc_address_prefix" "vpc-ap3" {
  name = "vpc-ap3"
  zone = "${var.zone3}"
  vpc  = "${ibm_is_vpc.vpc1.id}"
  cidr = "${var.zone3_cidr}"
}

resource "ibm_is_subnet" "subnet3" {
  name            = "subnet3"
  vpc             = "${ibm_is_vpc.vpc1.id}"
  zone            = "${var.zone3}"
  ipv4_cidr_block = "${var.zone3_cidr}"
  depends_on      = ["ibm_is_vpc_address_prefix.vpc-ap3"]
}

resource "ibm_is_instance" "instance3" {
  name    = "instance3"
  image   = "${var.image}"
  profile = "${var.profile}"

  primary_network_interface = {
    subnet = "${ibm_is_subnet.subnet3.id}"
  }
  vpc  = "${ibm_is_vpc.vpc1.id}"
  zone = "${var.zone3}"
  keys = ["${ibm_is_ssh_key.ssh1.id}"]
  user_data = "${data.template_cloudinit_config.cloud-init-apptier.rendered}"
}

resource "ibm_is_floating_ip" "floatingip3" {
  name = "fip3"
  target = "${ibm_is_instance.instance3.primary_network_interface.0.id}"
}

output "FloatingIP-3" {
    value = "${ibm_is_floating_ip.floatingip3.address}"
}

depends_on = ["ibm_is_floating_ip.floatingip1", "ibm_is_floating_ip.floatingip2", "ibm_is_floating_ip.floatingip3"]

resource "ibm_is_lb_pool_member" "lb1-pool-member3" {
  count = 1
  lb = "${ibm_is_lb.lb1.id}"
  pool = "${ibm_is_lb_pool.lb1-pool.id}"
  port = "80"
  target_address = "${ibm_is_instance.instance3.primary_network_interface.0.primary_ipv4_address}"
}
