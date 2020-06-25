# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

resource "oci_core_instance" "oci-deployer-client" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[0]["name"]
  compartment_id      = var.compartment_ocid
  display_name        = "deployer-${var.cluster_name}-${random_string.deploy_id.result}"
  image               = lookup(data.oci_core_images.node_pool_images.images[0], "id")
  shape               = var.deployer_shape

  create_vnic_details {
    subnet_id        = oci_core_subnet.oke-quickstart_lb_subnet.id
    display_name     = "deployer-${var.cluster_name}-${random_string.deploy_id.result}"
    hostname_label   = "deployer-${var.cluster_name}-${random_string.deploy_id.result}"
    assign_public_ip = true
  }

  extended_metadata = {
    roles               = "deployer"
    ssh_authorized_keys = "${var.public_ssh_key}"

    # Automate master instance configuration with cloud init run at launch time
    user_data = "${data.template_cloudinit_config.deployer.rendered}"
    tags      = "group:deployer"
  }

  # provisioner "local-exec" {
  #   when = destroy

  #   command = "/usr/local/bin/helm delete o5g-utils"

  #   environment = {
  #     OCI_CLI_CONFIG_FILE = "/root/ociconfig"
  #     OCI_CLI_AUTH = "instance_principal"
  #     KUBECONFIG = "/root/kubeconfig"
  #   }
 
  #   on_failure = continue
  # }

  timeouts {
    create = "60m"
  }
  depends_on = [oci_containerengine_node_pool.oke-quickstart_node_pool]
}

resource "oci_identity_dynamic_group" "deployer_dynamic_group" {
    compartment_id = var.tenancy_ocid
    description = "Dynamic group created by terraform for Deployer"
    matching_rule = "[ANY {instance.id = '${oci_core_instance.oci-deployer-client.id}'}]"
    name = "deployer-${random_string.deploy_id.result}"
    depends_on = [oci_core_instance.oci-deployer-client]
}

# Create policy to allow use oke instance principal for the deployer instance
resource "oci_identity_policy" "deployer_manage_oke_clusters_policy" {
  name           = "deployer-${random_string.deploy_id.result}"
  description    = "Policy created by terraform for Deployer"
  compartment_id = var.compartment_ocid
  statements     = ["Allow dynamic-group deployer-${random_string.deploy_id.result} to use clusters in compartment id ${var.compartment_ocid}", 
                  "Allow dynamic-group deployer-${random_string.deploy_id.result} to manage cluster-family in compartment id ${var.compartment_ocid}"]
  depends_on = [oci_identity_dynamic_group.deployer_dynamic_group]
}

## Local kubeconfig for when using Terraform locally. Not used by Oracle Resource Manager
resource "local_file" "kubeconfig" {
  content = data.oci_containerengine_cluster_kube_config.oke_cluster_kube_config.content
	filename = "generated/kubeconfig"
}

# resource "kubernetes_namespace" "commonservices_namespace" {
#   metadata {
#     name = "occne-infra"
#   }
#   depends_on = [oci_containerengine_node_pool.oke-quickstart_node_pool]
# }

# resource "kubernetes_namespace" "ocnrf_namespace" {
#   metadata {
#     name = "ocnrf"
#   }
#   depends_on = [oci_containerengine_node_pool.oke-quickstart_node_pool]
# }

# resource "kubernetes_namespace" "ocscp_namespace" {
#   metadata {
#     name = "ocscp"
#   }
#   depends_on = [oci_containerengine_node_pool.oke-quickstart_node_pool]
# }