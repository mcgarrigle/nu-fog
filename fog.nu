#!/usr/bin/env nu

module temp-fog {

  def variable [ s ] {
    $"\${($s | str screaming-snake-case)}"
  }

  def replace-map [] {
    items { |k,v| [ (variable $k), ($v | into string) ] } | into record
  }

  def kv [] {
    items { |k,v| { k:$k, v:$v } }
  }

  def template [ file ] {
    mut text = open $file 
    for i in ($env.map | kv) {
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
    virsh vol-list      --pool $env.vm.pool
  }

  def make-root-disk [ image, dest ] {
    truncate --reference $image --size $env.vm.root-size $dest
    virt-resize --quiet --expand $env.vm.root-device $image $dest
    upload $dest $dest
    $"vol=($env.vm.pool)/($dest),device=disk"
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
      --autostart
      --virt-type kvm
      --boot $env.vm.boot
      --osinfo $env.vm.osinfo
      --memory $env.vm.memory
      --vcpus $env.vm.cpus
      --disk $env.vm.disk
      --cloud-init $env.vm.cloud-init
      --network $env.vm.network
      --graphics none
      --noautoconsole)
  }

  def fog [] {
    let vm = collect
    $env.vm = $vm
    $env.map = $env.vm | replace-map
    print $env.map
    $env.vm.disk       = make-root-disk $"images/($vm.image)" $"($vm.guest).qcow2"
    $env.vm.cloud-init = make-cloud-init
    make-guest-domain
  }

}
