provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "centos-image" {
  name = "centos-image"
  source = "/home/dmartin/libvirt-storage-pool-openshift-ansible/CentOS-7-x86_64-GenericCloud.qcow2"
  pool = "ose"
}

resource "libvirt_network" "osenet" {
  name = "ose"
  mode = "nat"
  domain = "osc.test"
  addresses = ["192.168.100.0/24"]
}
resource "libvirt_cloudinit" "masterinit" {
    name = "master-init.iso"
    ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQChWJDwn44S7te6z8c+40LHeeUur+teItBKvNHli0OYLw7CKs1QFlSfUja9ciKHQG6PhpRvEtY/Vtt8Hbfu0SoCU9nyd2pANrtIfjfbQ8X7Q4AADHxfvwlPDeog2Utg125YtY1adoSXa1OiOyqO7jiZLT2h5KXMj1W0hsbDOCrwUnjOw0apIif9Tb0G/9dMktYz0z9+cnPLqjP+X5SqUQF47GPfUAeUw3lXS8gfImgH5qifiElUXz3FEi6goiOCo6CRZ7evCmup3mHsaBHo91DG+E8U7nP6OqaG3oPEF02kGt2KVHQ5mhpSQ1lPr84QiYlQwAgYAG12TYQmrR7kZp7x OpenShift-Key"
    local_hostname = "master.osc.test "
  pool = "ose"
}

resource "libvirt_cloudinit" "nodeinit" {
    name = "node-${count.index + 1}-init.iso"
    ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQChWJDwn44S7te6z8c+40LHeeUur+teItBKvNHli0OYLw7CKs1QFlSfUja9ciKHQG6PhpRvEtY/Vtt8Hbfu0SoCU9nyd2pANrtIfjfbQ8X7Q4AADHxfvwlPDeog2Utg125YtY1adoSXa1OiOyqO7jiZLT2h5KXMj1W0hsbDOCrwUnjOw0apIif9Tb0G/9dMktYz0z9+cnPLqjP+X5SqUQF47GPfUAeUw3lXS8gfImgH5qifiElUXz3FEi6goiOCo6CRZ7evCmup3mHsaBHo91DG+E8U7nP6OqaG3oPEF02kGt2KVHQ5mhpSQ1lPr84QiYlQwAgYAG12TYQmrR7kZp7x OpenShift-Key"
    local_hostname = "node-${count.index + 1}.osc.test"
  pool = "ose"
    count = 2
}

resource "libvirt_volume" "centos-master" {
  name = "centos-OSE-master"
  base_volume_id = "${libvirt_volume.centos-image.id}"
  pool = "ose"
}

resource "libvirt_volume" "centos-node" {
  name = "centos-OSE-node-${count.index}"
  base_volume_id = "${libvirt_volume.centos-image.id}"
  pool = "ose"
  count = 2
}

resource "libvirt_domain" "centos-node-domain" {
  name = "centos-OSE-node-${count.index}"
  cloudinit = "${element(libvirt_cloudinit.nodeinit.*.id, count.index + 1)}"
  memory = 3072
  network_interface {
    network_id = "${libvirt_network.osenet.id}"
    hostname ="node${count.index}.osc.test"
    mac = "52:54:00:00:00:a${count.index + 1}"
    addresses = ["192.168.100.10${count.index + 1}"]
  }
  disk {
       volume_id = "${element(libvirt_volume.centos-node.*.id, count.index + 1)}"
  }
  count = 2
}

resource "libvirt_domain" "centos-master-domain" {
  name = "centos-OSE-master"
  cloudinit = "${libvirt_cloudinit.masterinit.id}"
  memory = 3072
  network_interface {
    network_id = "${libvirt_network.osenet.id}"
    hostname ="master.osc.test"
    mac = "52:54:00:00:00:a0"
    addresses = ["192.168.100.100"]
  }
  disk {
       volume_id = "${libvirt_volume.centos-master.id}"
  }
}
