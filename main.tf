# Переменные
variable "os_type"   { default = "ubuntu" }
variable "img_src"   { default = "https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img" }
# variable "img_src"   { default = "ubuntu-18.04-server-cloudimg-amd64.img" }
variable "hostname"  { default = "ubnt1" }
variable "domain"    { default = "dev.local" }
variable "memoryMB"  { default = 1024 * 1 }
variable "cpu"       { default = 2 }
#locals {
#  name = "${var.override_name != "" ? var.override_name : "${var.product}-{$var.env}"}"
#}

# Специфические настройки терраформ и провайдеров
#####################################################
terraform {
  required_version = ">= 0.12"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
  }
}
######################################################
# Экземпляр провайдера (libvirt)
# Подключаемся локально 
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_pool" "os_pool" {
  name = "os_pool.ubuntu"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-${var.os_type}"
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "os_image" {
  #name   = var.hostname
  name   = "${var.hostname}.qcow2"
  pool   = "default"
  source = var.img_src
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "${var.hostname}-commoninit.iso"
  user_data      = "#cloud-config\n#\n\ngroups:\n  - ubuntu: [root,sys]\n\nusers:\n  - default\n  - name: test\n    gecos: test\n    primary_group: test\n    groups: users, admin, sudo\n    lock_passwd: false\n    plain_text_passwd: test\n\nssh_pwauth: True\nchpasswd:\n  list: |\n     root:master\n  expire: False\n"
  network_config = "version: 2\nethernets:\n  ens3:\n    dhcp4: true\n    dhcp6: false\n    addresses:\n        - 192.168.122.165/24\n    gateway4: 192.168.122.1\n    nameservers:\n      search: [dev.local, home.local]\n      addresses: [192.168.122.1, 8.8.8.8]"
  pool           = libvirt_pool.os_pool.name
}

# Создаём машину
resource "libvirt_domain" "main" {
  name   = var.hostname
  memory = var.memoryMB
  vcpu   = var.cpu
  disk {
    volume_id = libvirt_volume.os_image.id
  }
  
  network_interface {
    network_name   = "default"
  }
  
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = "true"
  }
  provisioner "ansible" {
    plays {
      playbook {
        file_path = "provision.yml"
      }
      inventory_file = "inventory"
      enabled = true
      verbose = true
    }
  }
}
