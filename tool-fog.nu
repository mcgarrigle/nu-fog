#!/usr/bin/env nu

def variable [ s ] {
  $"\${($s | str screaming-snake-case)}"
}

def replace-map [] {
  items { |k,v| [ (variable $k), ($v | into string) ] } | into record
}

def kv [] {
  $env.map | items { |k,v| { k:$k, v:$v } }
}

def template [ file ] {
  mut text = open $file 
  for i in (kv) {
    $text = $text | str replace --all $i.k $i.v
  }
  $text
}

def template-save [ file ] {
  let temp = mktemp --tmpdir
  template $file | save --force $temp
  # print ""
  # print $"// ($file)"
  # print ""
  # open $temp | print
  $temp
}

def upload [ source, dest ] {
  virsh vol-create-as --pool $env.vm.pool --name $dest --capacity "1m"
  virsh vol-upload    --pool $env.vm.pool --file $source --vol $dest
}

def make-root-disk [ image, dest ] {
  truncate --reference $image --size $env.vm.root-size $dest
  virt-resize --quiet --expand $env.vm.root-device $image $dest
  upload $dest $dest
  $"device=disk,vol=($env.vm.pool)/($dest)"
}

def make-cloud-init [] {
  let netw = template-save "cloud-init/network-config-static"
  let meta = template-save "cloud-init/meta-data"
  let user = template-save "cloud-init/user-data"
  $"user-data=($user),meta-data=($meta),network-config=($netw)"
}

def make-guest-domain [] {
  ( virt-install
    --import
    --name $env.vm.guest
    --virt-type kvm
    --boot $env.vm.boot
    --osinfo $env.vm.osinfo
    --memory $env.vm.memory
    --vcpus $env.vm.cpus
    --disk $env.vm.disk
    --cloud-init $env.vm.cloud-init
    --network $env.vm.network
    --graphics none
    --autostart
    --noautoconsole )
}

# -------------------------------------------
# commands

# list all domains
export def "fog list" [] {
  virsh list --all
  | detect columns --guess
  | rename id name state
}

# list all domains
export def "fog ls" [] {
  fog list
}

# list all volumes in pool
export def "fog vols" [
  pool = 'filesystems'  # pool to list
] {
  virsh vol-list --pool $pool
  | detect columns --guess
  | rename name path
}

# get internal data about domain
export def "fog info" [
  domain:string  # domain to examine
] {
  let dom = virsh dominfo --domain $domain
  ["name  value\n", $dom]
  | str join
  | detect columns --guess
}

# list disks attached to domain
export def "fog disks" [
  domain:string  # domain to examine
] {
  virsh domblklist --domain $domain
  | detect columns --guess
  | rename target source
}

# delete, undefine domain and delete volume
export def "fog rm" [
  domain:string                # domain to examine
  pool:string = 'filesystems'  # pool that stores root disk
] {
  virsh destroy $domain
  virsh undefine --nvram $domain
  virsh vol-delete --pool $pool --vol $"($domain).qcow2"
}

# consumes record containing domain definition and builds domain
export def "fog up" [] {
  let defn = collect
  $env.vm = $defn
  $env.map = $env.vm | replace-map
  $env.vm.disk       = make-root-disk $"($env.vm.image)" $"($env.vm.guest).qcow2"
  $env.vm.cloud-init = make-cloud-init
  make-guest-domain
}

export def fog [] {
  ignore
}
