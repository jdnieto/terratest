variable "stack"{
   default = "terraform"
}

variable "image" {
    default = "CentOS-7-x86_64-GenericCloud.qcow2"
}

variable "vmPool" {
    default = "default"
}

variable "publicKey" {
    default = ""
}

variable "nodeCount"  {
    default = "2"
}
