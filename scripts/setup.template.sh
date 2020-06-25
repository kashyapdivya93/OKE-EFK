#!/bin/bash -x

NAMESPACE=$(echo -n "${domain_name}" | sed "s/\.oraclevcn\.com//g")
FQDN_HOSTNAME=$(hostname -f)

echo $NAMESPACE
echo $FQDN_HOSTNAME

# Kubectl
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubectl

# Supporting tools
## Python 3
yum install -y python3
## git
yum install -y git
## Ansible
yum install -y ansible
## Helm 3
# curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
## Helm 2
wget https://get.helm.sh/helm-v2.16.6-linux-amd64.tar.gz
tar -zxvf helm-v2.16.6-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm

# OCI cli (Just for the Kubectl and OKE token v2.0.0)
mkdir /oci-cli
cd /oci-cli
wget -qO- -O oci-cli.zip "https://github.com/oracle/oci-cli/releases/download/v${oci_cli_version}/oci-cli-${oci_cli_version}.zip"
unzip oci-cli.zip -d .. > /dev/null
pip3 install oci_cli-*-py2.py3-none-any.whl
export OCI_CLI_CONFIG_FILE=/root/ociconfig
export OCI_CONFIG_FILE=/root/ociconfig
export OCI_CLI_AUTH=instance_principal

# Generate Kubeconfig to access created oke cluster
export KUBE_CONFIG=/root/kubeconfig
oci ce cluster create-kubeconfig --cluster-id ${oke_cluster_id} --file /root/kubeconfig  --region ${region} --token-version 2.0.0 --config-file /root/ociconfig --auth instance_principal

######################################
echo "Finished running setup.sh"