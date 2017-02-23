provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "terraform-base-image" {
  name = "${var.stack}-base-image"
  source = "/var/lib/libvirt/images/${var.image}"
  pool = "${var.vmPool}"
}

resource "libvirt_network" "terraformnet" {
  name = "${var.stack}net"
  mode = "nat"
  domain = "${var.stack}.com"
  addresses = ["192.168.200.0/24"]
}
resource "libvirt_cloudinit" "masterinit" {
    name = "master-${var.stack}-init.iso"
    ssh_authorized_key = "${var.publicKey}"
    local_hostname = "master.${var.stack}.com "
  pool = "${var.vmPool}"
}
resource "libvirt_cloudinit" "gwinit" {
    name = "gateway-${var.stack}-init.iso"
    ssh_authorized_key = "${var.publicKey}"
    local_hostname = "gw.${var.stack}.com "
  pool = "${var.vmPool}"
}

resource "libvirt_cloudinit" "nodeinit" {
    name = "node-${count.index + 1}-${var.stack}-init.iso"
    ssh_authorized_key = "${var.publicKey}"
    local_hostname = "node-${count.index + 1}.${var.stack}.com"
  pool = "${var.vmPool}"
    count = "${var.nodeCount}"
}

resource "libvirt_volume" "terraform-master" {
  name = "${var.stack}-master"
  base_volume_id = "${libvirt_volume.terraform-base-image.id}"
  pool = "${var.vmPool}"
}

resource "libvirt_volume" "terraform-gw" {
  name = "${var.stack}-gw"
  base_volume_id = "${libvirt_volume.terraform-base-image.id}"
  pool = "${var.vmPool}"
}

resource "libvirt_volume" "terraform-node" {
  name = "${var.stack}-node-${count.index + 1}"
  base_volume_id = "${libvirt_volume.terraform-base-image.id}"
  pool = "${var.vmPool}"
  count = "${var.nodeCount}"
}

resource "libvirt_domain" "terraform-node-domain" {
  name = "${var.stack}-node-${count.index + 1}"
  cloudinit = "${element(libvirt_cloudinit.nodeinit.*.id, count.index)}"
  memory = 1024
  network_interface {
    network_id = "${libvirt_network.terraformnet.id}"
    hostname ="node-${count.index + 1}.${var.stack}.com"
    mac = "52:54:00:00:00:a${count.index + 1}"
    addresses = ["192.168.200.10${count.index + 1}"]
  }
  disk {
       volume_id = "${element(libvirt_volume.terraform-node.*.id, count.index)}"
  }
  count = "${var.nodeCount}"
}

resource "libvirt_domain" "terraform-master-domain" {
  name = "${var.stack}-master"
  cloudinit = "${libvirt_cloudinit.masterinit.id}"
  memory = 1024
  vcpu = 1
  network_interface {
    network_id = "${libvirt_network.terraformnet.id}"
    hostname ="master.${var.stack}.com"
    mac = "52:54:00:00:00:a0"
    addresses = ["192.168.200.100"]
  }
  disk {
       volume_id = "${libvirt_volume.terraform-master.id}"
  }
}
resource "libvirt_domain" "terraform-gw-domain" {
  name = "${var.stack}-gw"
  cloudinit = "${libvirt_cloudinit.gwinit.id}"
  memory = 1024
  network_interface {
    network_id = "${libvirt_network.terraformnet.id}"
    hostname ="gw.${var.stack}.com"
    mac = "52:54:00:00:00:aa"
    addresses = ["192.168.200.99"]
  }
  disk {
       volume_id = "${libvirt_volume.terraform-gw.id}"
  }
}
