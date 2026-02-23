locals {
  zone = var.zone

  external_vpc_cidr   = "10.10.0.0/16"
  public_subnet_cidr  = "10.10.1.0/24"
  private_subnet_cidr = "10.10.2.0/24"
  lb_subnet_cidr      = "10.10.3.0/24"
  natgw_subnet_cidr   = "10.10.4.0/24"

  # Pin to a known-good console selection (G3) to avoid G2 quota failures.
  server_image_number = "107029409"
  server_spec_code    = "s2-g3a"
}

resource "ncloud_vpc" "external" {
  name            = "${var.project_name}-vpc"
  ipv4_cidr_block = local.external_vpc_cidr
}

resource "ncloud_network_acl" "external" {
  vpc_no = ncloud_vpc.external.id
  name   = "${var.project_name}-nacl"
}

resource "ncloud_route_table" "public" {
  vpc_no                = ncloud_vpc.external.id
  supported_subnet_type = "PUBLIC"
  name                  = "${var.project_name}-rt-public"
}

resource "ncloud_route_table" "private" {
  vpc_no                = ncloud_vpc.external.id
  supported_subnet_type = "PRIVATE"
  name                  = "${var.project_name}-rt-private"
}

resource "ncloud_subnet" "public" {
  vpc_no         = ncloud_vpc.external.id
  subnet         = local.public_subnet_cidr
  zone           = local.zone
  network_acl_no = ncloud_network_acl.external.id
  subnet_type    = "PUBLIC"
  usage_type     = "GEN"
  name           = "${var.project_name}-subnet-public"
}

resource "ncloud_subnet" "private" {
  vpc_no         = ncloud_vpc.external.id
  subnet         = local.private_subnet_cidr
  zone           = local.zone
  network_acl_no = ncloud_network_acl.external.id
  subnet_type    = "PRIVATE"
  usage_type     = "GEN"
  name           = "${var.project_name}-subnet-private"
}

resource "ncloud_subnet" "lb" {
  vpc_no         = ncloud_vpc.external.id
  subnet         = local.lb_subnet_cidr
  zone           = local.zone
  network_acl_no = ncloud_network_acl.external.id
  subnet_type    = "PUBLIC"
  usage_type     = "LOADB"
  name           = "${var.project_name}-subnet-lb"
}

resource "ncloud_subnet" "natgw" {
  vpc_no         = ncloud_vpc.external.id
  subnet         = local.natgw_subnet_cidr
  zone           = local.zone
  network_acl_no = ncloud_network_acl.external.id
  subnet_type    = "PUBLIC"
  usage_type     = "NATGW"
  name           = "${var.project_name}-subnet-natgw"
}

resource "ncloud_route_table_association" "public_assoc" {
  route_table_no = ncloud_route_table.public.id
  subnet_no      = ncloud_subnet.public.id
}

resource "ncloud_route_table_association" "public_lb_assoc" {
  route_table_no = ncloud_route_table.public.id
  subnet_no      = ncloud_subnet.lb.id
}

resource "ncloud_route_table_association" "public_natgw_assoc" {
  route_table_no = ncloud_route_table.public.id
  subnet_no      = ncloud_subnet.natgw.id
}

resource "ncloud_route_table_association" "private_assoc" {
  route_table_no = ncloud_route_table.private.id
  subnet_no      = ncloud_subnet.private.id
}

resource "ncloud_nat_gateway" "external" {
  vpc_no = ncloud_vpc.external.id
  zone   = local.zone
  name   = "${var.project_name}-natgw"

  subnet_no = ncloud_subnet.natgw.id
}

resource "ncloud_route" "private_default_nat" {
  route_table_no         = ncloud_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  target_type            = "NATGW"
  target_name            = ncloud_nat_gateway.external.name
  target_no              = ncloud_nat_gateway.external.id
}

resource "ncloud_vpc_peering" "external_to_coss" {
  name          = "${var.project_name}-peering"
  source_vpc_no = ncloud_vpc.external.id
  target_vpc_no = var.coss_vpc_no
}

resource "ncloud_route" "private_to_coss" {
  route_table_no         = ncloud_route_table.private.id
  destination_cidr_block = var.coss_vpc_cidr
  target_type            = "VPCPEERING"
  target_name            = ncloud_vpc_peering.external_to_coss.name
  target_no              = ncloud_vpc_peering.external_to_coss.id
}

resource "ncloud_route" "public_to_coss" {
  route_table_no         = ncloud_route_table.public.id
  destination_cidr_block = var.coss_vpc_cidr
  target_type            = "VPCPEERING"
  target_name            = ncloud_vpc_peering.external_to_coss.name
  target_no              = ncloud_vpc_peering.external_to_coss.id
}

resource "ncloud_access_control_group" "alb" {
  vpc_no = ncloud_vpc.external.id
  name   = "${var.project_name}-acg-alb"
}

resource "ncloud_access_control_group_rule" "alb_rule" {
  access_control_group_no = ncloud_access_control_group.alb.id

  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "80"
    description = "allow http from internet"
  }

  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "443"
    description = "allow https from internet"
  }

  outbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
    description = "allow all outbound"
  }
}

resource "ncloud_access_control_group" "web" {
  vpc_no = ncloud_vpc.external.id
  name   = "${var.project_name}-acg-web"
}

resource "ncloud_access_control_group_rule" "web_rule" {
  access_control_group_no = ncloud_access_control_group.web.id

  inbound {
    protocol    = "TCP"
    ip_block    = local.lb_subnet_cidr
    port_range  = "80"
    description = "allow 80 from lb subnet"
  }

  inbound {
    protocol    = "TCP"
    ip_block    = var.ssl_vpn_cidr
    port_range  = "22"
    description = "allow ssh from ssl vpn"
  }

  outbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
    description = "allow all outbound"
  }
}

resource "ncloud_access_control_group" "api" {
  vpc_no = ncloud_vpc.external.id
  name   = "${var.project_name}-acg-api"
}

resource "ncloud_access_control_group_rule" "api_rule" {
  access_control_group_no = ncloud_access_control_group.api.id

  inbound {
    protocol    = "TCP"
    ip_block    = var.ssl_vpn_cidr
    port_range  = "22"
    description = "allow ssh from ssl vpn"
  }

  inbound {
    protocol    = "TCP"
    ip_block    = local.private_subnet_cidr
    port_range  = "8080"
    description = "allow 8080 from private subnet(web)"
  }

  inbound {
    protocol    = "TCP"
    ip_block    = var.coss_vpc_cidr
    port_range  = "8080"
    description = "allow 8080 from coss cidr"
  }

  outbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "1-65535"
    description = "allow all outbound"
  }
}

resource "ncloud_network_interface" "web" {
  subnet_no             = ncloud_subnet.private.id
  name                  = "${var.project_name}-nic-web"
  access_control_groups = [ncloud_access_control_group.web.id]
  # provider 문서 확인 필요: 버전에 따라 access_control_groups 대신 access_control_group_no_list 사용
}

resource "ncloud_network_interface" "api" {
  subnet_no             = ncloud_subnet.private.id
  name                  = "${var.project_name}-nic-api"
  access_control_groups = [ncloud_access_control_group.api.id]
  # provider 문서 확인 필요: 버전에 따라 access_control_groups 대신 access_control_group_no_list 사용
}

resource "ncloud_init_script" "web" {
  name = "${var.project_name}-init-web"
  content = templatefile("${path.module}/user_data.sh", {
    api_private_ip = ncloud_network_interface.api.private_ip
  })
}

resource "ncloud_init_script" "api" {
  name = "${var.project_name}-init-api"
  content = templatefile("${path.module}/user_data_api.sh", {
    coss_api_base_url = var.coss_api_base_url
  })
}

resource "ncloud_login_key" "default" {
  key_name = "${var.project_name}-login-key"
}

resource "ncloud_server" "web" {
  subnet_no           = ncloud_subnet.private.id
  name                = "external-web-svr01"
  server_image_number = local.server_image_number
  server_spec_code    = local.server_spec_code
  login_key_name      = ncloud_login_key.default.key_name
  network_interface {
    network_interface_no = ncloud_network_interface.web.id
    order                = 0
  }
  init_script_no = ncloud_init_script.web.id
}

resource "ncloud_server" "api" {
  subnet_no           = ncloud_subnet.private.id
  name                = "external-api-svr01"
  server_image_number = local.server_image_number
  server_spec_code    = local.server_spec_code
  login_key_name      = ncloud_login_key.default.key_name
  network_interface {
    network_interface_no = ncloud_network_interface.api.id
    order                = 0
  }
  init_script_no = ncloud_init_script.api.id
}

resource "ncloud_lb_target_group" "web_tg" {
  vpc_no      = ncloud_vpc.external.id
  name        = "${var.project_name}-tg-web"
  target_type = "VSVR"
  protocol    = "HTTP"
  port        = 80

  health_check {
    protocol    = "HTTP"
    port        = 80
    url_path    = "/"
    http_method = "GET"
  }
}

resource "ncloud_lb_target_group_attachment" "web_attach" {
  target_group_no = ncloud_lb_target_group.web_tg.id
  target_no_list  = [ncloud_server.web.id]
}

resource "ncloud_lb" "external" {
  name           = "${var.project_name}-alb"
  network_type   = "PUBLIC"
  type           = "APPLICATION"
  subnet_no_list = [ncloud_subnet.lb.id]
  idle_timeout   = 60
}

resource "ncloud_lb_listener" "http" {
  load_balancer_no = ncloud_lb.external.id
  protocol         = "HTTP"
  port             = 80
  target_group_no  = ncloud_lb_target_group.web_tg.id
}

resource "ncloud_lb_listener" "https" {
  load_balancer_no     = ncloud_lb.external.id
  protocol             = "HTTPS"
  port                 = 443
  target_group_no      = ncloud_lb_target_group.web_tg.id
  ssl_certificate_no   = var.alb_ssl_certificate_no
  tls_min_version_type = "TLSV12"
  use_http2            = true
}

