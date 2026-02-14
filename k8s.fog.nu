#!/usr/bin/env nu

# vim: set filetype=yaml :

use utilities.nu *
use hypervisor.nu
use fog.nu

import HYPERVISORS

hypervisor use local


let base = {
  guest: ?
  image: rocky10.qcow2
  osinfo: rocky9
  cpus: 2
  memory: 4096

  boot: uefi
  pool: filesystems
  root-device: /dev/sda4
  root-size: "+10G"

  network: "network=bridge"
  network-device: enp1s0
  bootproto: static
  ip-address: ?
  gateway-address: 192.168.1.254
  dns-server: 1.1.1.1

  user: $env.USER
  password: letmein123
  ssh-public-key: (cat ~/.ssh/id_rsa.pub)
}


let nodes = [
  { guest: k8s1.mac.wales, ip-address: 192.168.1.41 }
  { guest: k8s2.mac.wales, ip-address: 192.168.1.42 }
  { guest: k8s3.mac.wales, ip-address: 192.168.1.43 }
]

$nodes | each {|node| $base | merge $node | fog up }

ignore
