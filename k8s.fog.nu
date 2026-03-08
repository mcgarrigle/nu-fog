#!/usr/bin/env nu
# vim: set filetype=yaml :

source $nu.env-path

use hypervisor.nu
use fog.nu

# get base VM definition

source base.nu

let nodes = [
  { guest: k8s1.mac.wales, ip-address: 192.168.1.41 }
  { guest: k8s2.mac.wales, ip-address: 192.168.1.42 }
  { guest: k8s3.mac.wales, ip-address: 192.168.1.43 }
]

hypervisor use local

$nodes | each {|node| $base | merge $node | fog up }

ignore
