provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "terraform-base-image" {
  name = "ansible-base-image"
  source = "/var/lib/libvirt/images/${var.image}"
  pool = "${var.vmPool}"
}

resource "libvirt_network" "ansiblenet" {
  name = "ansiblenet"
  mode = "nat"
  domain = "${var.stack}.com"
  addresses = ["${var.fullNet}"]
}
resource "libvirt_cloudinit" "managerinit" {
    name = "manager-${var.stack}-init.iso"
    ssh_authorized_key = "${var.publicKey}"
    local_hostname = "manager.${var.stack}.com "
  pool = "${var.vmPool}"
}

resource "libvirt_cloudinit" "nodeinit" {
    name = "node-${count.index + 1}-${var.stack}-init.iso"
    ssh_authorized_key = "${var.publicKey}"
    local_hostname = "node-${count.index + 1}.${var.stack}.com"
  pool = "${var.vmPool}"
    count = "${var.nodeCount}"
}

resource "libvirt_volume" "terraform-manager" {
  name = "ansible-manager"
  base_volume_id = "${libvirt_volume.terraform-base-image.id}"
  pool = "${var.vmPool}"
}

resource "libvirt_volume" "terraform-node" {
  name = "ansible-node-${count.index + 1}"
  base_volume_id = "${libvirt_volume.terraform-base-image.id}"
  pool = "${var.vmPool}"
  count = "${var.nodeCount}"
}

resource "libvirt_domain" "terraform-node-domain" {
  name = "ansible-node-${count.index + 1}"
  cloudinit = "${element(libvirt_cloudinit.nodeinit.*.id, count.index)}"
  memory = 1024
  network_interface {
    network_id = "${libvirt_network.ansiblenet.id}"
    hostname ="node-${count.index + 1}.${var.stack}.com"
    mac = "52:54:00:00:01:a${count.index + 1}"
    addresses = ["${var.baseNet}${count.index + 110}"]
  }
  disk {
       volume_id = "${element(libvirt_volume.terraform-node.*.id, count.index)}"
  }
  count = "${var.nodeCount}"
}

resource "libvirt_domain" "terraform-manager-domain" {
  name = "ansible-master"
  cloudinit = "${libvirt_cloudinit.managerinit.id}"
  memory = 1024
  vcpu = 1
  network_interface {
    network_id = "${libvirt_network.ansiblenet.id}"
    hostname ="manager.${var.stack}.com"
    mac = "52:54:00:00:01:a0"
    addresses = ["${var.baseNet}100"]
  }
  disk {
       volume_id = "${libvirt_volume.terraform-manager.id}"
  }
}
