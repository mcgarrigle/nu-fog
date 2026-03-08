#!/usr/bin/env nu

# vim: set filetype=yaml :

use fog.nu

# get base VM definition

source base.nu

let nodes = [
  { guest: t1, ip-address: 192.168.1.31 }
  { guest: t2, ip-address: 192.168.1.32 }
  { guest: t3, ip-address: 192.168.1.33 }
]
  
$nodes | each {|node| $base | merge $node | fog up }

ignore
