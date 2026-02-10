#!/usr/bin/env nu

def variable [ s ] {
  $"\${($s | str screaming-snake-case)}"
}

def template-map [ $vm ] {
  $vm | items {|k, v| [ (variable $k), ($v | into string) ] }
}

def template [] {
  mut text = collect
  $env.vars | reduce --fold $text {|v, t| $t | str replace --all $v.0 $v.1}
}

def template-save [ file ] {
  let temp = mktemp --tmpdir
  open $file | template | save --force $temp
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
  let user = template-save "cloud-init/user-data"
  let meta = template-save "cloud-init/meta-data"
  let netw = template-save "cloud-init/network-config-static"
  $"user-data=($user),meta-data=($meta),network-config=($netw)"
}

def make-domain [ vm ] {
  ( virt-install
    --import
    --name $vm.guest
    --virt-type kvm
    --boot $vm.boot
    --osinfo $vm.osinfo
    --memory $vm.memory
    --vcpus $vm.cpus
    --disk $vm.disk
    --cloud-init $vm.cloud-init
    --network $vm.network
    --graphics none
    --autostart
    --noautoconsole )
}

# -------------------------------------------

def make-virtual-machine [ vm:record ] {
  $env.vars          = template-map $vm
  $env.vm            = $vm
  $env.vm.disk       = make-root-disk $"($env.vm.image)" $"($env.vm.guest).qcow2"
  $env.vm.cloud-init = make-cloud-init
  make-domain $env.vm
}

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
  try { virsh destroy $domain }
  try { virsh undefine --nvram $domain }
  virsh vol-delete --pool $pool --vol $"($domain).qcow2"
}

# consumes record containing domain definition and builds domain
export def "fog up" [] {
  let vm = collect | from json
  make-virtual-machine $vm
}

export def fog [] {
  ignore
}
