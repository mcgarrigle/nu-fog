
Prerequisites
```
$ sudo dnf install qemu-kvm-common
$ sudo dnf install cloud-utils-growpart
$ sudo dnf install guestfs-tools
```
Example guest configuration
```nushell
let vm = {
  guest: tt
  image: rocky10.qcow2
  osinfo: rocky9
  cpus: 2
  memory: 4096

  boot: uefi
  pool: filesystems
  root-device: /dev/sda4
  root-size: "+10G"

  network: "network=bridge"
  network-device: enp1s0
  bootproto: dhcp

  user: $env.USER
  password: letmein123
  ssh-public-key: (cat ~/.ssh/id_rsa.pub)
}

$vm | fog up  # send definiton to fog to create
```
Guest Definition Variables

| Key             | Purpose   |
| --------------- | --------- |
| guest           | Guest hostname |
| pool            | libvirt pool to store VM disk |
| image           | Image file stored in {FOG-HOME}/images |
| osinfo          | osinfo (use 'osinfo-query os' to find a value to use) |
| cpus            | Number of vcpu to allocate |
| memory          | Memory allocated (in MiB) |
| boot            | Boot order (default uefi') |
| -               |           |
| root-device     | / device to expand (use virt-df to find root FS) |
| root-size       | Size to extend image by, the root FS will be expanded |
| -               |           |
| network         | libvirt network to attach to |
| network-device  | eth0 or enp0s1 or other |
| bootproto       | 'static' or 'dhcp' |
| ip-address      | Static IP address |
| gateway-address | Default route |
| dns-server      | DNS server |
| -               |           |
| user            | Username to inject into VM |
| password        | Password for ${USER}   |
| ssh-public_key  | SSH public key to inject into ${USER} |
