#!/bin/bash -x

export PATH=$PATH:/usr/local/bin

# Variables for kubeconfig token v2.0.0
export OCI_CLI_CONFIG_FILE=/root/ociconfig
export OCI_CLI_AUTH=instance_principal
export KUBECONFIG=/root/kubeconfig

# 
cd /root

# Helm2 init (Ugly workaround to use old helm2)
helm init --upgrade --wait
helm repo remove local
# End of the Ugly workaround


# Deploy MySQL
helm install -f mysql-values.yaml --name o5g-mysql --namespace occne-infra stable/mysql > helm.mysql.log

# Deploy EFK (hack to proper set the namespace)
wget https://raw.githubusercontent.com/oracle/cloudnative/master/observability-and-analysis/logging/efk-stack/efk.tar.gz 2>&1 >/dev/null
tar -xzvf ./efk.tar.gz 2>&1 >/dev/null
sed -i.bak 's/devops/occne-infra/g' efk/templates/*.yaml 2>&1 >/dev/null
rm -rf efk/templates/*.bak 2>&1 >/dev/null
helm install --name o5g-efk --namespace occne-infra efk/ > helm.efk.log

kubectl create configmap landingpage --namespace occne-infra \
        --from-file=services/landing/index.html \
        --from-file=services/landing/style.css

kubectl create configmap landingpagelogos --namespace occne-infra \
        --from-file=services/landing/logos/

kubectl create -f services/landing.yaml --namespace occne-infra

echo "Finished running deploy.sh"
