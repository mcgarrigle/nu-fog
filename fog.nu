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

def upload [ volume, pool ] {
  virsh vol-create-as --pool $pool --name $volume --capacity "1m"
  virsh vol-upload    --pool $pool --file $volume --vol $volume
}

def make-root-disk [ vm ] {
  let volume = $"($vm.guest).qcow2"
  truncate --reference $vm.image --size $vm.root-size $volume
  virt-resize --quiet --expand $vm.root-device $vm.image $volume
  upload $volume $vm.pool
  $"device=disk,vol=($vm.pool)/($volume)"
}

def make-cloud-init [ vm ] {
  $env.vars = template-map $vm
  let user  = template-save "cloud-init/user-data"
  let meta  = template-save "cloud-init/meta-data"
  let netw  = template-save $"cloud-init/network-config-($vm.bootproto)"
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

def make-virtual-machine [] {
  mut vm = collect
  print $"building ($vm.guest)\n"
  $vm.disk       = make-root-disk $vm
  $vm.cloud-init = make-cloud-init $vm
  make-domain $vm
}

# -------------------------------------------

# commands

# list all domains
export def "fog list" [] {
  virsh list --all
  | detect columns --ignore-box-chars
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
  | detect columns --ignore-box-chars
  | rename name path
}

# get internal data about domain
export def "fog info" [
  domain:string  # domain to examine
] {
  virsh dominfo --domain $domain
  | lines
  | compact --empty
  | split column ':'
  | str trim
  | rename name value
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
  make-virtual-machine
  ignore
}

export def main [] {
  ignore
}
