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

# (workaround to be able to terraform destroy. fixed on v2)
kubectl create ns occne-infra
kubectl create ns ocnrf
kubectl create ns ocscp

# Deploy MySQL
helm install -f mysql-values.yaml --name o5g-mysql --namespace occne-infra stable/mysql > helm.mysql.log

# Temp - Grafana Dashboards
# Workaround waiting the solution to escape {{ on helm
sed -i.bak 's/{{ include "setup.fullname" . }}/custom/g' o5g-grafana-dashboards.yaml
sed -i.bak '/{{ include "setup.labels" . | indent 4 }}/d' o5g-grafana-dashboards.yaml
kubectl create -f o5g-grafana-dashboards.yaml --namespace occne-infra

# Deploy Common Services Helm Chart
helm dependency update commonservices
helm install --name o5g-utils --namespace occne-infra commonservices/ > helm.commonservices.log

# Deploy Jaeger
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm install --name o5g-utils-jaeger --namespace occne-infra jaegertracing/jaeger \
  --set provisionDataStore.cassandra=false \
  --set storage.type=elasticsearch \
  --set storage.elasticsearch.host=o5g-efk-elasticsearch-logging \
  --set storage.elasticsearch.port=9200

# Deploy EFK (hack to proper set the namespace)
wget https://raw.githubusercontent.com/oracle/cloudnative/master/observability-and-analysis/logging/efk-stack/efk.tar.gz 2>&1 >/dev/null
tar -xzvf ./efk.tar.gz 2>&1 >/dev/null
sed -i.bak 's/devops/occne-infra/g' efk/templates/*.yaml 2>&1 >/dev/null
rm -rf efk/templates/*.bak 2>&1 >/dev/null
helm install --name o5g-efk --namespace occne-infra efk/ > helm.efk.log

# Create ingresses (Temp, will change to Istio when available)
kubectl create -f o5g-ingress.yaml --namespace occne-infra

# (workaround for the load test, using node external ip)
FIRST_NODE_IP=$(kubectl get nodes -o jsonpath='{ $.items[0].status.addresses[?(@.type=="ExternalIP")].address }')
sed -i.bak 's/FIRST_NODE_IP/'$FIRST_NODE_IP'/g' ocnrf-custom-values-1.4.0-dishoci-min.yaml
sed -i.bak 's/FIRST_NODE_IP/'$FIRST_NODE_IP'/g' ocscp-custom-values-1.4.0-dishoci.yaml

# Deploy nrf - API Gateway
helm install -f ocnrf-custom-values-1.4.0-dishoci-min.yaml --name ocnrf --namespace ocnrf https://objectstorage.us-ashburn-1.oraclecloud.com/p/7r_jKkr6pu70lJm15dEiaEzZM2RpXDmVin2ZzpqXc1c/n/ociateam/b/NF_Helm_charts/o/ocnrf-1.4.0.tgz > helm.ocnrf.log

# Deploy scp
helm install -f ocscp-custom-values-1.4.0-dishoci.yaml --name ocscp --namespace ocscp https://objectstorage.us-ashburn-1.oraclecloud.com/p/Xw8M3zJLixbZ-88peUWLJl5URIxXCVA7p6aLm88xkeI/n/ociateam/b/NF_Helm_charts/o/ocscp-1.4.0.tgz > helm.ocscp.log

# Install vegeta load test tool
wget https://github.com/tsenart/vegeta/releases/download/v12.8.3/vegeta-12.8.3-linux-arm64.tar.gz 2>&1 >/dev/null
tar -xzvf ./vegeta-12.8.3-linux-arm64.tar.gz 2>&1 >/dev/null

# Deploy langing page service
wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/O33Pz1SnPRY0PnbD0_74Goi1xthPwAQaaj-O56eorq0/n/ociateam/b/landingpage/o/landingpage-v001.zip 2>&1 >/dev/null
unzip landingpage-v001.zip 2>&1 >/dev/null

kubectl create configmap landingpage --namespace occne-infra \
        --from-file=services/landing/index.html \
        --from-file=services/landing/style.css

kubectl create configmap landingpagelogos --namespace occne-infra \
        --from-file=services/landing/logos/

kubectl create -f services/landing.yaml --namespace occne-infra

echo "Finished running deploy.sh"