# Переменные базовые
variable "os_type"      { default = "test" }
variable "os_ver"       { default = "0" }
variable "os_rel"       { default = "rel" }
variable "img_src"      { default = "/home/luba/trimg/ubuntu-18.04-server-cloudimg-amd64.img" }
variable "domain"       { default = "dev.local" }
variable "memoryMB"     { default = 512 }
variable "cpu"          { default = 1 }
variable "network_name" { default = "default" }

# Переменные cloud-init
variable "init_user_data"       { 
  type    = string
  default = "" 
}
variable "init_network_config"  { 
  type    = string
  default = "" 
}

#locals {
#  name = "${var.override_name != "" ? var.override_name : "${var.product}-{$var.env}"}"
#}
