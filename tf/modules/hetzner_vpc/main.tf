terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
}

resource "hcloud_network" "this" {
  name     = var.network_name
  ip_range = var.network_ip_range
}

resource "hcloud_network_subnet" "cloud" {
  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.subnet_ip_range
}

resource "hcloud_network_subnet" "vswitch" {
  count = var.vswitch_id == null ? 0 : 1

  network_id   = hcloud_network.this.id
  type         = "vswitch"
  network_zone = var.network_zone
  ip_range     = var.vswitch_subnet_ip_range
  vswitch_id   = var.vswitch_id
}

resource "hcloud_network_route" "default" {
  count = var.create_default_route ? 1 : 0

  network_id  = hcloud_network.this.id
  destination = var.route_destination
  gateway     = var.route_gateway
}

resource "hcloud_ssh_key" "devops" {
  name       = var.ssh_key_name
  public_key = var.ssh_public_key
}

resource "hcloud_server" "this" {
  name        = var.server_name
  server_type = var.server_type
  image       = var.server_image
  location    = var.server_location
  ssh_keys    = [hcloud_ssh_key.devops.id]

  user_data = <<-EOT
    #cloud-config
    users:
      - default
      - name: ${var.devops_user}
        shell: /bin/bash
        groups: sudo
        sudo: ALL=(ALL) NOPASSWD:ALL
    write_files:
      - path: /tmp/${var.devops_user}_authorized_key
        owner: root:root
        permissions: "0644"
        content: |
          ${var.ssh_public_key}
          ${var.ssh_fips_public_key}
    runcmd:
      - install -d -m 700 -o ${var.devops_user} -g ${var.devops_user} /home/${var.devops_user}/.ssh
      - install -m 600 -o ${var.devops_user} -g ${var.devops_user} /tmp/${var.devops_user}_authorized_key /home/${var.devops_user}/.ssh/authorized_keys
      - chown ${var.devops_user}:${var.devops_user} /home/${var.devops_user}
      - rm -f /tmp/${var.devops_user}_authorized_key
  EOT

  lifecycle {
    ignore_changes = [
      user_data,
      labels,
      placement_group_id,
      firewall_ids,
    ]
  }
}

resource "hcloud_server_network" "private" {
  server_id  = hcloud_server.this.id
  network_id = hcloud_network.this.id
  ip         = var.server_private_ip
}

resource "terraform_data" "dedicated_server" {
  input = {
    name       = var.dedicated_server_name
    public_ip  = var.dedicated_server_public_ip
    private_ip = var.dedicated_server_private_ip
    vlan_id    = var.dedicated_server_vlan_id
    subnet     = var.vswitch_subnet_ip_range
    vswitch_id = var.vswitch_id
  }
}
