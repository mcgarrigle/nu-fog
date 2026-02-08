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

def kv [] {
  items { |k,v| { k:$k, v:$v } }
}

def template [ file ] {
  mut text = open $file 
  for i in ($map | kv) {
    $vm | get $i.v | let value
    $text = $text | str replace --all $i.k $value
  }
  $text
}

def upload [ disk, dest ] {
  virsh vol-create-as --pool $vm.pool --name $dest --capacity "1m"
  virsh vol-upload --pool $vm.pool --vol $dest --file $dest
  virsh vol-list --pool $vm.pool
}

def make-root-disk [ source, dest ] {
  truncate --reference $source --size $"+($vm.root-size)" $dest
  virt-resize --quiet --expand $vm.root-device $source $dest
  upload $source $dest
}

def make-cloud-init [] {
  let netw_conf = mktemp --tmpdir --suffix ".network" 
  let meta_data = mktemp --tmpdir --suffix ".meta"
  let user_data = mktemp --tmpdir --suffix ".user"
  template "cloud-init/network-config-static" | save --force $netw_conf
  template "cloud-init/meta-data"             | save --force $meta_data
  template "cloud-init/user-data"             | save --force $user_data
  $"user-data=($user_data),meta-data=($meta_data),network-config=($netw_conf)"
}

def fog [] {
  mut vm = collect
  $vm.disk       = make-root-disk $"images/($vm.image)" $"($vm.guest).qcow2"
  $vm.cloud-init = make-cloud-init
}
