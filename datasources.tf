# Copyright (c) 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# Gets a list of supported images based on the shape, operating_system and operating_system_version provided
data "oci_core_images" "node_pool_images" {
  compartment_id = var.compartment_ocid
  operating_system = var.image_operating_system
  operating_system_version = var.image_operating_system_version
  shape = var.node_pool_shape
  sort_by = "TIMECREATED"
  sort_order = "DESC"
}

# Gets a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

resource "random_string" "deploy_id" {
  length = 4
  special = false
}

# Deployer data
data "template_file" "setup-template" {
  template = "${file("${path.module}/scripts/setup.template.sh")}"

  vars = {
    domain_name                = "test-domain"
    oci_cli_version            = var.deployer_oci_cli_version
    oke_cluster_id             = oci_containerengine_cluster.oke-quickstart_cluster.id
    region                     = var.region
  }
}

data "template_file" "setup-preflight" {
  template = "${file("${path.module}/scripts/setup.preflight.sh")}"
}

data "template_file" "oci-config-template" {
  template = "${file("${path.module}/scripts/ociconfig.template")}"

  vars = {
    tenancy_ocid     = var.tenancy_ocid
    region           = var.region
  }
}

data "template_file" "deploy-template" {
  template = "${file("${path.module}/scripts/deploy.template.sh")}"
}

data "template_file" "commonservices-values-template" {
  template = "${file("${path.module}/charts/commonservices/values.yaml")}"
}
data "template_file" "commonservices-requirements-template" {
  template = "${file("${path.module}/charts/commonservices/requirements.yaml")}"
}
data "template_file" "commonservices-chart-template" {
  template = "${file("${path.module}/charts/commonservices/Chart.yaml")}"
}
data "template_file" "commonservices-templates-helpers-template" {
  template = "${file("${path.module}/charts/commonservices/templates/_helpers.tpl")}"
}
data "template_file" "commonservices-templates-notes-template" {
  template = "${file("${path.module}/charts/commonservices/templates/NOTES.txt")}"
}
data "template_file" "commonservices-templates-o5g-grafana-datasources-template" {
  template = "${file("${path.module}/charts/commonservices/templates/o5g-grafana-datasources.yaml")}"
}
data "template_file" "commonservices-templates-o5g-grafana-dashboards-template" {
  template = "${file("${path.module}/charts/commonservices/templates/o5g-grafana-dashboards.yaml")}"
}
data "template_file" "mysql-values-template" {
  template = "${file("${path.module}/charts/mysql-values.yaml")}"
}
data "template_file" "ocnrf-values-template" {
  template = "${file("${path.module}/charts/ocnrf-custom-values-1.4.0-dishoci-min.yaml")}"
  vars = {
    access_endpoint   = "FIRST_NODE_IP" # 0.0.0.0
  }
}
data "template_file" "ocscp-values-template" {
  template = "${file("${path.module}/charts/ocscp-custom-values-1.4.0-dishoci.yaml")}"
  vars = {
    access_endpoint   = "FIRST_NODE_IP" # 0.0.0.0
  }
}
data "template_file" "o5g-ingress-template" {
  template = "${file("${path.module}/charts/o5g-ingress.yaml")}"
}

data "template_file" "cloud-init-file" {
  template = "${file("${path.module}/cloud_init/bootstrap.template.yaml")}"

  vars = {
    setup_preflight_sh_content                                = "${base64gzip(data.template_file.setup-preflight.rendered)}"
    setup_template_sh_content                                 = "${base64gzip(data.template_file.setup-template.rendered)}"
    ociconfig_template_content                                = "${base64gzip(data.template_file.oci-config-template.rendered)}"
    deploy_template_content                                   = "${base64gzip(data.template_file.deploy-template.rendered)}"
    commonservices_values_template_content                    = "${base64gzip(data.template_file.commonservices-values-template.rendered)}"
    commonservices_requirements_content                       = "${base64gzip(data.template_file.commonservices-requirements-template.rendered)}"
    commonservices_chart_content                              = "${base64gzip(data.template_file.commonservices-chart-template.rendered)}"
    commonservices_templates_helpers_content                  = "${base64gzip(data.template_file.commonservices-templates-helpers-template.rendered)}"
    commonservices_templates_notes_content                    = "${base64gzip(data.template_file.commonservices-templates-notes-template.rendered)}"
    commonservices_templates_o5g_grafana_datasources_content  = "${base64gzip(data.template_file.commonservices-templates-o5g-grafana-datasources-template.rendered)}"
    commonservices_templates_o5g_grafana_dashboards_content   = "${base64gzip(data.template_file.commonservices-templates-o5g-grafana-dashboards-template.rendered)}"
    mysql_values_content                                      = "${base64gzip(data.template_file.mysql-values-template.rendered)}"
    ocnrf_values_content                                      = "${base64gzip(data.template_file.ocnrf-values-template.rendered)}"
    ocscp_values_content                                      = "${base64gzip(data.template_file.ocscp-values-template.rendered)}"
    o5g_ingress_content                                      = "${base64gzip(data.template_file.o5g-ingress-template.rendered)}"
  }
}

data "template_cloudinit_config" "deployer" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "bootstrap.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud-init-file.rendered}"
  }
}

data "oci_containerengine_cluster_kube_config" "oke_cluster_kube_config" {
    cluster_id = oci_containerengine_cluster.oke-quickstart_cluster.id
}

