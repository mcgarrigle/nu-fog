#!/usr/bin/env nu

# vim: set filetype=yaml :

source $nu.env-path

use hypervisor.nu
use fog.nu

# get base VM definition

source base.nu

def build [ node ] {
  hypervisor use $node.host
  $base | merge $node | fog up
}

def delete [ node ] {
  hypervisor use $node.host
  fog del $node.guest
}

let nodes = [
  { guest: node1.mac.wales, ip-address: 192.168.1.21, host: dwt  }
  { guest: node2.mac.wales, ip-address: 192.168.1.22, host: smol }
  { guest: node3.mac.wales, ip-address: 192.168.1.23, host: wee  }
]
  
$nodes | each {|node| build $node }

ignore
