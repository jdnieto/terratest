provider "libvirt" {
    uri = "qemu:///system"
}
resource "libvirt_domain" "terraform_test" {
  name = "terraform_test"
  disk {
        volume_id = "${libvirt_volume.volume.id}"
    }
}
#resource "libvirt_volume" "centos" {
#  name = "centos_base"
#  base_volume_id = "/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud.qcow2"
#}

resource "libvirt_volume" "volume" {
    name = "terra_centos"
#    base_volume_id = "${libvirt_volume.centos.id}"
    base_volume_id = "/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud.qcow2"
}
