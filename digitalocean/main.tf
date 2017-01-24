variable "do_token" {}

variable "droplet_base_image" {
  type = "string"
  default = "ubuntu-16-04-x64"
}

variable "droplet_region" {
  type = "string"
  default = "nyc2"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
    token = "${var.do_token}"
}

resource "digitalocean_ssh_key" "default" {
    name = "Vault Test"
    public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# Create a web server
resource "digitalocean_droplet" "web" {
    # Obtain your ssh_key id number via your account. See Document https://developers.digitalocean.com/documentation/v2/#list-all-keys
    ssh_keys           = ["${digitalocean_ssh_key.default.id}"]
    image              = "${var.droplet_base_image}"
    region             = "${var.droplet_region}"
    size               = "512mb"
    private_networking = true
    name               = "vault-test-webserver"
    tags               = ["web"]

    connection {
        type     = "ssh"
        private_key = "${file("~/.ssh/id_rsa")}"
        user     = "root"
        timeout  = "2m"
    }

    provisioner "remote-exec" {
        inline = [
          "useradd -m ubuntu"
        ]
    }

    provisioner "file" {
        source = "./Gemfile"
        destination = "/home/ubuntu/Gemfile"
    }

    provisioner "file" {
        source = "./config.yml"
        destination = "/home/ubuntu/config.yml"
    }

    provisioner "file" {
        source = "./vault_connector.rb"
        destination = "/home/ubuntu/vault_connector.rb"
    }

    provisioner "file" {
        source = "./app.rb"
        destination = "/home/ubuntu/app.rb"
    }

    provisioner "remote-exec" {
        script = "provision_web.sh"
    }
}

output "web_public_ip" {
    value = "${digitalocean_droplet.web.ipv4_address}"
}
