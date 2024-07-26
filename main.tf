locals {
  certs_dir          = "./certs"
  keys_dir           = "${local.certs_dir}/keys"
  client_config_file = "./client_config.ovpn"
}

resource "aws_acm_certificate" "ca" {
  private_key      = file("${local.keys_dir}/ca.key")
  certificate_body = file("${local.certs_dir}/ca.pem")
  tags             = var.tags
}

resource "aws_acm_certificate" "server" {
  private_key       = file("${local.keys_dir}/server.key")
  certificate_body  = file("${local.certs_dir}/server.pem")
  certificate_chain = file("${local.certs_dir}/ca.pem")
  tags              = var.tags
}

###

resource "aws_ec2_client_vpn_endpoint" "example" {
  description            = "Example Client VPN endpoint"
  server_certificate_arn = aws_acm_certificate.server.arn
  client_cidr_block      = "10.180.180.0/22"
  self_service_portal    = "enabled"
  dns_servers            = ["8.8.8.8", "9.9.9.9"]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.server.arn
  }

  connection_log_options {
    enabled = false
  }
  tags = {
    Name = "example"
  }
}


resource "aws_ec2_client_vpn_network_association" "private" {
  for_each               = aws_subnet.private
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.example.id
  subnet_id              = each.value.id
}

resource "aws_ec2_client_vpn_route" "internet" {
  for_each               = aws_ec2_client_vpn_network_association.private
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.example.id
  destination_cidr_block = "0.0.0.0/0"
  target_vpc_subnet_id   = each.value.subnet_id
}

resource "aws_ec2_client_vpn_authorization_rule" "example" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.example.id
  target_network_cidr    = "0.0.0.0/0"
  authorize_all_groups   = true
}

resource "local_file" "script" {
  filename = "aws_get_client_file.sh"
  content  = "aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id ${aws_ec2_client_vpn_endpoint.example.id} --region ${var.region}"
}

data "external" "vpn_config_base" {
  program = ["bash", local_file.script.filename]
  query = {
    version = "1"
  }
}

resource "local_file" "config" {
  filename = local.client_config_file
  content  = <<EOF
${data.external.vpn_config_base.result["ClientConfiguration"]}
<cert>
${file("${local.certs_dir}/client.pem")}
</cert>
<key>
${file("${local.keys_dir}/client.key")}
</key>
EOF
}