backend "consul" {
  address = "consul:8500"
  path = "vault"
  advertise_addr = ""
}

listener "tcp" {
  address = "vault:8200"
  tls_disable = 1
}
