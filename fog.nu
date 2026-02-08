#!/usr/bin/env nu

let map = {
  "${NETWORK}": network
  "${NETWORK_DEVICE}": network-device
  "${USER}": user
  "${PASSWORD}": password
  "${SSH_PUBLIC_KEY}": ssh-public-key
  "${IP_ADDRESS}": ip-address
  "${GATEWAY_ADDRESS}": gateway-address
  "${DNS_SERVER}": dns-server
}

let t = template "cloud-init/network-config-static"
print $t

def kv [] {
  items { |k,v| { k:$k, v:$v } }
}

def template [ file ] {
  mut text = open $file 
  for i in ($map | kv) {
    $text = $text | str replace $i.k $"//($i.v)//"
  }
  $text
}

def fog [] {
  let vm = collect
  print $vm
}
