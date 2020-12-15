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
  name = format("os_pool.%s", var.os_type)
  type = "dir"
  path = format("/tmp/terraform-provider-libvirt-pool-%s", var.os_type)
}

# Нам нужно разместить образ ОС в пул libvirt для дальнейшего использования
resource "libvirt_volume" "os_image" {
  name   = format("%s-%s-%s.qcow2",var.os_type, var.os_ver, var.os_rel)
  pool   = "default"
  source = var.img_src
  format = "qcow2"
}
# и сгенерированный образ cloud init в тот же, для удобства пул (но не обязательно!)
resource "libvirt_cloudinit_disk" "commoninit" {
  name           = format("%s-%s-%s-commoninit.iso", var.os_type, var.os_ver, var.os_rel)
  user_data      = var.init_user_data
  network_config = var.init_network_config
  pool           = libvirt_pool.os_pool.name
}

# Создаём машину
resource "libvirt_domain" "main" {
  name   = format("%s-%s-%s", var.os_type, var.os_ver, var.os_rel)
  memory = var.memoryMB
  vcpu   = var.cpu
  disk {
    volume_id = libvirt_volume.os_image.id
  }
  
  network_interface {
    network_name   = var.network_name
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
