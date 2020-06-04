module "local_execution" {
  source  = "../generic_modules/local_exec"
  enabled = var.pre_deployment
}

# This locals entry is used to store the IP addresses of all the machines.
# Autogenerated addresses example based in 10.0.0.0/16
# Iscsi server: 10.0.0.4
# Monitoring: 10.0.0.5
# Hana ips: 10.0.1.10, 10.0.2.11 (hana machines must be in different subnets)
# Hana cluster vip: 192.168.1.10 (virtual ip address must be in a different range than the vpc)
# Netweaver ips: 10.0.3.30, 10.0.4.31, 10.0.3.32, 10.0.4.33 (netweaver ASCS and ERS must be in different subnets)
# Netweaver virtual ips: 192.168.1.30, 192.168.1.31, 192.168.1.32, 192.168.1.33 (virtual ip addresses must be in a different range than the vpc)
# DRBD ips: 10.0.5.20, 10.0.6.21
# DRBD cluster vip: 192.168.1.20 (virtual ip address must be in a different range than the vpc)
# If the addresses are provided by the user will always have preference
locals {
  iscsi_ip      = var.iscsi_srv_ip != "" ? var.iscsi_srv_ip : cidrhost(local.infra_subnet_address_range, 4)
  monitoring_ip = var.monitoring_srv_ip != "" ? var.monitoring_srv_ip : cidrhost(local.infra_subnet_address_range, 5)

  # The next locals are used to map the ip index with the subnet range (something like python enumerate method)
  hana_ip_start    = 10
  hana_ips         = length(var.hana_ips) != 0 ? var.hana_ips : [for index in range(var.hana_count) : cidrhost(element(local.hana_subnet_address_range, index % 2), index + local.hana_ip_start)]
  hana_cluster_vip = var.hana_cluster_vip != "" ? var.hana_cluster_vip : cidrhost(var.virtual_address_range, local.hana_ip_start)

  drbd_ip_start    = 20
  drbd_ips         = length(var.drbd_ips) != 0 ? var.drbd_ips : [for index in range(2) : cidrhost(element(local.drbd_subnet_address_range, index % 2), index + local.drbd_ip_start)]
  drbd_cluster_vip = var.drbd_cluster_vip != "" ? var.drbd_cluster_vip : cidrhost(var.virtual_address_range, local.drbd_ip_start)

  # range(4) hardcoded as we always deploy 4 nw machines
  netweaver_ip_start    = 30
  netweaver_count       = var.netweaver_enabled ? (var.netweaver_ha_enabled ? 4 : 2) : 0
  netweaver_ips         = length(var.netweaver_ips) != 0 ? var.netweaver_ips : [for index in range(local.netweaver_count) : cidrhost(element(local.netweaver_subnet_address_range, index % 2), index + local.netweaver_ip_start)]
  netweaver_virtual_ips = length(var.netweaver_virtual_ips) != 0 ? var.netweaver_virtual_ips : [for ip_index in range(local.netweaver_ip_start, local.netweaver_ip_start + local.netweaver_count) : cidrhost(var.virtual_address_range, ip_index)]

  # Check if iscsi server has to be created
  iscsi_enabled = var.sbd_storage_type == "iscsi" && (var.hana_count > 1 && var.hana_cluster_sbd_enabled == true || var.drbd_enabled && var.drbd_cluster_sbd_enabled == true || local.netweaver_count > 2 && var.netweaver_cluster_sbd_enabled == true) ? true : false
}

module "drbd_node" {
  source                 = "./modules/drbd_node"
  drbd_count             = var.drbd_enabled == true ? 2 : 0
  instance_type          = var.drbd_instancetype
  aws_region             = var.aws_region
  availability_zones     = data.aws_availability_zones.available.names
  os_image               = var.drbd_os_image
  os_owner               = var.drbd_os_owner
  vpc_id                 = local.vpc_id
  subnet_address_range   = local.drbd_subnet_address_range
  key_name               = aws_key_pair.key-pair.key_name
  security_group_id      = local.security_group_id
  route_table_id         = aws_route_table.route-table.id
  aws_credentials        = var.aws_credentials
  aws_access_key_id      = var.aws_access_key_id
  aws_secret_access_key  = var.aws_secret_access_key
  host_ips               = local.drbd_ips
  sbd_enabled            = var.drbd_cluster_sbd_enabled
  drbd_cluster_vip       = local.drbd_cluster_vip
  drbd_data_disk_size    = var.drbd_data_disk_size
  drbd_data_disk_type    = var.drbd_data_disk_type
  public_key_location    = var.public_key_location
  private_key_location   = var.private_key_location
  cluster_ssh_pub        = var.cluster_ssh_pub
  cluster_ssh_key        = var.cluster_ssh_key
  iscsi_srv_ip           = join("", module.iscsi_server.iscsisrv_ip)
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  reg_additional_modules = var.reg_additional_modules
  additional_packages    = var.additional_packages
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  devel_mode             = var.devel_mode
  monitoring_enabled     = var.monitoring_enabled
  provisioner            = var.provisioner
  background             = var.background
  qa_mode                = var.qa_mode
  on_destroy_dependencies = [
    aws_route.public,
    aws_security_group_rule.ssh,
    aws_security_group_rule.outall
  ]
}

module "iscsi_server" {
  source                 = "./modules/iscsi_server"
  iscsi_count            = local.iscsi_enabled == true ? 1 : 0
  aws_region             = var.aws_region
  availability_zones     = data.aws_availability_zones.available.names
  subnet_ids             = aws_subnet.infra-subnet.*.id
  os_image               = var.iscsi_os_image
  os_owner               = var.iscsi_os_owner
  instance_type          = var.iscsi_instancetype
  key_name               = aws_key_pair.key-pair.key_name
  security_group_id      = local.security_group_id
  private_key_location   = var.private_key_location
  host_ips               = [local.iscsi_ip]
  lun_count              = var.iscsi_lun_count
  iscsi_disk_size        = var.iscsi_disk_size
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  reg_additional_modules = var.reg_additional_modules
  additional_packages    = var.additional_packages
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  provisioner            = var.provisioner
  background             = var.background
  qa_mode                = var.qa_mode
  on_destroy_dependencies = [
    aws_route_table_association.infra-subnet-route-association,
    aws_route.public,
    aws_security_group_rule.ssh,
    aws_security_group_rule.outall
  ]
}

module "netweaver_node" {
  source                    = "./modules/netweaver_node"
  netweaver_count           = local.netweaver_count
  instance_type             = var.netweaver_instancetype
  name                      = "netweaver"
  aws_region                = var.aws_region
  availability_zones        = data.aws_availability_zones.available.names
  os_image                  = var.netweaver_os_image
  os_owner                  = var.netweaver_os_owner
  vpc_id                    = local.vpc_id
  subnet_address_range      = local.netweaver_subnet_address_range
  key_name                  = aws_key_pair.key-pair.key_name
  security_group_id         = local.security_group_id
  route_table_id            = aws_route_table.route-table.id
  efs_enable_mount          = var.netweaver_enabled == true && var.drbd_enabled == false ? true : false
  efs_file_system_id        = join("", aws_efs_file_system.netweaver-efs.*.id)
  aws_credentials           = var.aws_credentials
  aws_access_key_id         = var.aws_access_key_id
  aws_secret_access_key     = var.aws_secret_access_key
  s3_bucket                 = var.netweaver_s3_bucket
  netweaver_product_id      = var.netweaver_product_id
  netweaver_inst_folder     = var.netweaver_inst_folder
  netweaver_extract_dir     = var.netweaver_extract_dir
  netweaver_swpm_folder     = var.netweaver_swpm_folder
  netweaver_sapcar_exe      = var.netweaver_sapcar_exe
  netweaver_swpm_sar        = var.netweaver_swpm_sar
  netweaver_sapexe_folder   = var.netweaver_sapexe_folder
  netweaver_additional_dvds = var.netweaver_additional_dvds
  netweaver_nfs_share       = var.drbd_enabled ? "${local.drbd_cluster_vip}:/HA1" : "${join("", aws_efs_file_system.netweaver-efs.*.dns_name)}:"
  hana_ip                   = var.hana_ha_enabled ? local.hana_cluster_vip : element(local.hana_ips, 0)
  host_ips                  = local.netweaver_ips
  virtual_host_ips          = local.netweaver_virtual_ips
  public_key_location       = var.public_key_location
  private_key_location      = var.private_key_location
  ha_enabled                = var.netweaver_ha_enabled
  sbd_enabled               = var.netweaver_cluster_sbd_enabled
  sbd_storage_type          = var.sbd_storage_type
  iscsi_srv_ip              = join("", module.iscsi_server.iscsisrv_ip)
  cluster_ssh_pub           = var.cluster_ssh_pub
  cluster_ssh_key           = var.cluster_ssh_key
  reg_code                  = var.reg_code
  reg_email                 = var.reg_email
  reg_additional_modules    = var.reg_additional_modules
  ha_sap_deployment_repo    = var.ha_sap_deployment_repo
  devel_mode                = var.devel_mode
  provisioner               = var.provisioner
  background                = var.background
  monitoring_enabled        = var.monitoring_enabled
  on_destroy_dependencies = [
    aws_route.public,
    aws_security_group_rule.ssh,
    aws_security_group_rule.outall
  ]
}

module "hana_node" {
  source                 = "./modules/hana_node"
  hana_count             = var.hana_count
  instance_type          = var.hana_instancetype
  name                   = var.name
  scenario_type          = var.scenario_type
  aws_region             = var.aws_region
  availability_zones     = data.aws_availability_zones.available.names
  os_image               = var.hana_os_image
  os_owner               = var.hana_os_owner
  vpc_id                 = local.vpc_id
  subnet_address_range   = local.hana_subnet_address_range
  key_name               = aws_key_pair.key-pair.key_name
  security_group_id      = local.security_group_id
  route_table_id         = aws_route_table.route-table.id
  aws_credentials        = var.aws_credentials
  aws_access_key_id      = var.aws_access_key_id
  aws_secret_access_key  = var.aws_secret_access_key
  host_ips               = local.hana_ips
  hana_data_disk_type    = var.hana_data_disk_type
  hana_inst_master       = var.hana_inst_master
  hana_inst_folder       = var.hana_inst_folder
  hana_platform_folder   = var.hana_platform_folder
  hana_sapcar_exe        = var.hana_sapcar_exe
  hdbserver_sar          = var.hdbserver_sar
  hana_extract_dir       = var.hana_extract_dir
  hana_disk_device       = var.hana_disk_device
  hana_fstype            = var.hana_fstype
  hana_cluster_vip       = local.hana_cluster_vip
  ha_enabled             = var.hana_ha_enabled
  private_key_location   = var.private_key_location
  sbd_enabled            = var.hana_cluster_sbd_enabled
  sbd_storage_type       = var.sbd_storage_type
  iscsi_srv_ip           = join("", module.iscsi_server.iscsisrv_ip)
  cluster_ssh_pub        = var.cluster_ssh_pub
  cluster_ssh_key        = var.cluster_ssh_key
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  reg_additional_modules = var.reg_additional_modules
  additional_packages    = var.additional_packages
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  devel_mode             = var.devel_mode
  hwcct                  = var.hwcct
  qa_mode                = var.qa_mode
  provisioner            = var.provisioner
  background             = var.background
  monitoring_enabled     = var.monitoring_enabled
  on_destroy_dependencies = [
    aws_route.public,
    aws_security_group_rule.ssh,
    aws_security_group_rule.outall
  ]
}

module "monitoring" {
  source                 = "./modules/monitoring"
  instance_type          = var.monitor_instancetype
  key_name               = aws_key_pair.key-pair.key_name
  security_group_id      = local.security_group_id
  monitoring_srv_ip      = local.monitoring_ip
  private_key_location   = var.private_key_location
  aws_region             = var.aws_region
  availability_zones     = data.aws_availability_zones.available.names
  os_image               = var.monitoring_os_image
  os_owner               = var.monitoring_os_owner
  subnet_ids             = aws_subnet.infra-subnet.*.id
  timezone               = var.timezone
  reg_code               = var.reg_code
  reg_email              = var.reg_email
  reg_additional_modules = var.reg_additional_modules
  additional_packages    = var.additional_packages
  ha_sap_deployment_repo = var.ha_sap_deployment_repo
  provisioner            = var.provisioner
  background             = var.background
  monitoring_enabled     = var.monitoring_enabled
  hana_targets           = concat(local.hana_ips, var.hana_ha_enabled ? [local.hana_cluster_vip] : []) # we use the vip to target the active hana instance
  drbd_targets           = var.drbd_enabled ? local.drbd_ips : []
  netweaver_targets      = var.netweaver_enabled ? local.netweaver_virtual_ips : []
  on_destroy_dependencies = [
    aws_route_table_association.infra-subnet-route-association,
    aws_route.public,
    aws_security_group_rule.ssh,
    aws_security_group_rule.outall
  ]
}
