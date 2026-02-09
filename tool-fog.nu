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

def save-template [ file ] {
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
  let netw = save-template "cloud-init/network-config-static"
  let meta = save-template "cloud-init/meta-data"
  let user = save-template "cloud-init/user-data"
  $"user-data=($user),meta-data=($meta),network-config=($netw)"
}

def make-guest-domain [] {
  ( virt-install -v
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

export def "fog list" [] {
  virsh list --all
}

export def "fog ls" [] {
  fog list
}

export def "fog vols" [ pool = 'filesystems' ] {
  virsh vol-list --pool $pool
}

export def "fog info" [ guest ] {
  virsh dominfo    --domain $guest
  virsh domblklist --domain $guest
}

export def "fog rm" [ guest, pool = 'filesystems' ] {
  virsh destroy $guest
  virsh undefine --nvram $guest
  virsh vol-delete --pool $pool --vol $"($guest).qcow2"
}

export def "fog up" [] {
  let vmdef = collect
  $env.vm = $vmdef
  $env.map = $env.vm | replace-map
  $env.vm.disk       = make-root-disk $"($env.vm.image)" $"($env.vm.guest).qcow2"
  $env.vm.cloud-init = make-cloud-init
  make-guest-domain
}

export def fog [] {
  ignore
}
