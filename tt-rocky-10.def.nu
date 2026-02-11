#!/usr/bin/env nu

# vim: set filetype=yaml :

#source ~/.config/nushell/env.nu

use hypervisor.nu *
use fog.nu *

hypervisor import

hypervisor use local


def ssh-public-key [] {
  cat ~/.ssh/id_rsa.pub
}


let vm = {
  guest: "tt"
  image: "rocky10.qcow2"
  osinfo: "rocky9"
  cpus: 2
  memory: 4096

  boot: uefi
  pool: "filesystems"
  root-device: "/dev/sda4"
  root-size: "+10G"

  network: "network=bridge"
  network-device: "enp1s0"
  ip-address: "192.168.1.24"
  gateway-address: "192.168.1.254"
  dns-server: "1.1.1.1"

  user: $env.USER
  password: "letmein123"
  ssh-public-key: (ssh-public-key)
}

$vm | fog up
