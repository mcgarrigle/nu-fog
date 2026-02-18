#!/usr/bin/env nu

# vim: set filetype=yaml :

use fog.nu

let vm = {
  guest: tt
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
  ip-address: 192.168.1.20
  gateway-address: 192.168.1.254
  dns-server: 1.1.1.1

  user: $env.USER
  password: letmein123
  ssh-public-key: (cat ~/.ssh/id_rsa.pub)
  ssh-ca-user-key: (cat ./keys/ssh_ca_user_key.pub)
}

$vm | fog up
