variable "common_variables" {
  description = "Output of the common_variables module"
}

variable "az_region" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  type = string
}

variable "network_subnet_id" {
  type = string
}

variable "sec_group_id" {
  type = string
}

variable "storage_account" {
  type = string
}

variable "hana_count" {
  type    = string
  default = "2"
}

variable "name" {
  type    = string
  default = "hana"
}

variable "hana_instance_number" {
  description = "HANA database instance number"
  type        = string
  default     = "00"
}

variable "scenario_type" {
  description = "Deployed scenario type. Available options: performance-optimized, cost-optimized"
  default     = "performance-optimized"
}

variable "storage_account_name" {
  description = "Azure storage account where SAP hana installation files are stored"
  type        = string
}

variable "storage_account_key" {
  description = "Azure storage account access key"
  type        = string
}

variable "enable_accelerated_networking" {
  type = bool
}

variable "host_ips" {
  description = "ip addresses to set to the nodes"
  type        = list(string)
}

variable "sles4sap_uri" {
  type    = string
  default = ""
}

variable "hana_public_publisher" {
  type = string
}

variable "hana_public_offer" {
  type = string
}

variable "hana_public_sku" {
  type = string
}

variable "hana_public_version" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_E4s_v3"
}

variable "admin_user" {
  type    = string
  default = "azadmin"
}

variable "bastion_enabled" {
  description = "Use a bastion machine to create the ssh connections"
  type        = bool
  default     = true
}

variable "bastion_host" {
  description = "Bastion host address"
  type        = string
  default     = ""
}

variable "bastion_private_key" {
  description = "Path to a SSH private key used to connect to the bastion. It must be provided if bastion is enabled"
  type        = string
  default     = ""
}

variable "sbd_enabled" {
  description = "Enable sbd usage in the HA cluster"
  type        = bool
  default     = true
}

variable "sbd_storage_type" {
  description = "Choose the SBD storage type. Options: iscsi"
  type        = string
  default     = "iscsi"
}

variable "iscsi_srv_ip" {
  description = "iscsi server address"
  type        = string
}

variable "cluster_ssh_pub" {
  description = "path for the public key needed by the cluster"
  type        = string
}

variable "cluster_ssh_key" {
  description = "path for the private key needed by the cluster"
  type        = string
}

variable "hwcct" {
  description = "Execute HANA Hardware Configuration Check Tool to bench filesystems"
  type        = bool
  default     = false
}

variable "hana_inst_master" {
  type = string
}

variable "hana_inst_folder" {
  type    = string
  default = "/sapmedia/HANA"
}

variable "hana_platform_folder" {
  description = "Path to the hana platform media, relative to the 'hana_inst_master' mounting point"
  type        = string
  default     = ""
}

variable "hana_sapcar_exe" {
  description = "Path to the sapcar executable, relative to the 'hana_inst_master' mounting point"
  type        = string
  default     = ""
}

variable "hana_archive_file" {
  description = "Path to the HANA database server installation SAR archive or HANA platform archive file in zip or rar format, relative to the 'hana_inst_master' mounting point. Use this parameter if the hana media archive is not already extracted"
  type        = string
  default     = ""
}

variable "hana_extract_dir" {
  description = "Absolute path to folder where SAP HANA archive will be extracted"
  type        = string
  default     = "/sapmedia/HANA"
}

variable "hana_fstype" {
  description = "Filesystem type to use for HANA"
  type        = string
  default     = "xfs"
}

variable "hana_cluster_vip" {
  description = "Virtual ip for the hana cluster"
  type        = string
}

variable "hana_cluster_vip_secondary" {
  description = "IP address used to configure the hana cluster floating IP for the secondary node in an Active/Active mode"
  type        = string
  default     = ""
}

variable "ha_enabled" {
  description = "Enable HA cluster in top of HANA system replication"
  type        = bool
  default     = true
}

variable "hana_data_disks_configuration" {
  type = map
  default = {
    disks_type       = "Premium_LRS,Premium_LRS,Premium_LRS,Premium_LRS,Premium_LRS,Premium_LRS,Premium_LRS"
    disks_size       = "128,128,128,128,128,128,128"
    caching          = "None,None,None,None,None,None,None"
    writeaccelerator = "false,false,false,false,false,false,false"
    # The next variables are used during the provisioning
    luns     = "0,1#2,3#4#5#6"
    names    = "data#log#shared#usrsap#backup"
    lv_sizes = "100#100#100#100#100"
    paths    = "/hana/data#/hana/log#/hana/shared#/usr/sap#/hana/backup"
  }
  description = <<EOF
    This map describes how the disks will be formatted to create the definitive configuration during the provisioning.
    disks_type, disks_size, caching and writeaccelerator are used during the disks creation. The number of elements must match in all of them
    "#" character is used to split the volume groups, while "," is used to define the logical volumes for each group
    The number of groups splitted by "#" must match in all of the entries
    names -> The names of the volume groups (example datalog#shared#usrsap#backup)
    luns  -> The luns or disks used for each volume group. The number of luns must match with the configured in the previous disks variables (example 0,1,2#3#4#5)
    sizes -> The size dedicated for each logical volume and folder (example 70,100#100#100#100)
    paths -> Folder where each volume group will be mounted (example /hana/data,/hana/log#/hana/shared#/usr/sap#/hana/backup)
  EOF
}
