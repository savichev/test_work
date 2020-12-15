# Переменные
os_type      = "ubuntu"
os_ver       = "18.04"
os_rel       = "server"
#img_src      = "https://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img"
img_src      = "/home/luba/trimg/ubuntu-18.04-server-cloudimg-amd64.img"
#hostname     = format("%s-%s-%s",var.os_type, var.os_ver, var.os_rel)
domain       = "dev.local"
memoryMB     = 1024 * 1
cpu          = 2
network_name = "default"

init_user_data = <<-EOT
  #cloud-config
  #
  ssh_pwauth: True
  users:
    - name: test
      gecos: test
      primary_group: test
      groups: users, admin, sudo
      lock_passwd: false
      plain_text_passwd: test
EOT

init_network_config = <<-EOT
  version: 2
  ethernets:
    ens3:
      dhcp4: true
      dhcp6: false
      addresses:
        - 192.168.122.165/24
      gateway4: 192.168.122.1
      nameservers:
        search: [dev.local, home.local]
        addresses: [192.168.122.1, 8.8.8.8]
EOT
