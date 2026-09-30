resource "proxmox_virtual_environment_vm" "test_vm" {
  name      = "terraform-minimal"
  node_name = "traverse-town"

  clone {
    vm_id = 9000
    full  = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.210/24"
        gateway = "192.168.1.254"
      }
    }

    user_account {
      username = "anton"
      keys     = [trimspace(file("~/.ssh/id_ed25519.pub"))]
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}
