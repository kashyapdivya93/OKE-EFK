# OKE EFK terraform scripts

Deploys the whole solution in 15 minutes or less. Including OKE Cluster, Node Pools, helm charts, Services to Kubernetes and applications 

---

## Steps (Using Terraform and OCI CloudShell)
###### (If not using OCI CloudShell, you need to have the terraform, OCI cli and kubectl installed and configured on workstation that will be used)

1. Create a folder for the Terraform scripts: e.g.: `mkdir oke-efk && cd oke-efk`
1. Get the project: `https://github.com/mrabhiram/OKE-EFK.git`
1. Unzip. e.g.: `unzip OKE-EFK.zip`
1. Copy the file `terraform.tfvars.example` to `terraform.tfvars` and update the tenancy_ocid and compartment_ocid variables `cp terraform.tfvars.example terraform.tfvars`
1. Run the command `terraform init` to init the Terraform and providers
1. Run the command `terraform apply` to deploy everything.
    * Takes near 8 min for the OKE cluster be deployed
    * Takes near 5 min to run the app deployment scripts, after the OKE cluster is ready


## Steps (Using OCI Console UI and Resource Manager)

1. Download the stack from here: (https://github.com/mrabhiram/OKE-EFK.git)
1. Open the Resource Manager on the OCI Console. e.g.: https://console.us-ashburn-1.oraclecloud.com/resourcemanager/stacks/create
1. Drag-and-Drop the OKE-EFK.zip, optionally set any variables needed and click Create
1. Select "Terraform Apply"
    * Takes near 8 min for the OKE cluster be deployed
    * Takes near 5 min to run the app deployment scripts, after the OKE cluster is ready

## Accessing the new OKE cluster created
1. Go to the project folder (e.g.: cd cloud.poc.tf.oracle5gaware)
1. Run the command `export KUBECONFIG=./generated/kubeconfig` to use the kubeconfig for the created cluster
1. Run the command `kubectl get pods --all-namespaces` to to see all the pods created

## Accessing the logs (Kibana)
1. Run the command `kubectl get svc -n occne-infra o5g-efk-kibana-logging` to get the EXTERNAL-IP of the kibana loadbalancer.
1. Open the browser and point to <EXTERNAL_IP> to open the kibana ui.




