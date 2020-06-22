# This plan will be used to deploy the puppet agent to Proxmox
plan manage_proxmox::prep_proxmox() {
  # apply_prep('proxmox')
  apply('proxmox') {

    proxmox_api::qemu::clone {'test':
      node     => 'pmx',
      clone_id => 1001,
      newid    => 9998,
    }
  }
}
