output "external_vpc_no" {
  value = ncloud_vpc.external.id
}

output "public_subnet_no" {
  value = ncloud_subnet.public.id
}

output "private_subnet_no" {
  value = ncloud_subnet.private.id
}

output "nat_gateway_no" {
  value = ncloud_nat_gateway.external.id
}

output "vpc_peering_no" {
  value = ncloud_vpc_peering.external_to_coss.id
}

output "web_network_interface_no" {
  value = ncloud_network_interface.web.id
}

output "api_network_interface_no" {
  value = ncloud_network_interface.api.id
}

output "web_server_no" {
  value = ncloud_server.web.id
}

output "api_server_no" {
  value = ncloud_server.api.id
}

output "alb_no" {
  value = ncloud_lb.external.id
}

output "alb_domain" {
  value = ncloud_lb.external.domain
}
