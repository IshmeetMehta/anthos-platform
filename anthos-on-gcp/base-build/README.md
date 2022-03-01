# Build Anthos Application Development platform with all feature and components on Google Cloud Platform

# Pre-requistes

1. Install Google Cloud SDK
2. Install Terraform
3. Active Anthos trial license

## Steps to deploy the platform:

Components and features : Activate Google Cloud APIs, Google Kubernetes Engine, Custom VPCs, Anthos Config Management, Anthos Config Connector, Multi-cluster services, Anthos Service Mesh and a custom Cloud build deployment pipeline.

1. Clone this repo
1. Set variables that will be used in multiple commands:

    ```bash
    FOLDER_ID = [FOLDER]
    BILLING_ACCOUNT = [BILLING_ACCOUNT]
    PROJECT_ID = [PROJECT_ID]
    ```

1. Create project:

    ```bash
    gcloud auth login
    gcloud projects create $PROJECT_ID --name=$PROJECT_ID --folder=$FOLDER_ID
    gcloud alpha billing projects link $PROJECT_ID --billing-account $BILLING_ACCOUNT
    gcloud config set project $PROJECT_ID
    ```

1. Create cluster using terraform using defaults other than the project:

    ```bash
    # obtain user access credentials to use for Terraform commands
    gcloud auth application-default login

    # continue in /terraform directory
    cd terraform
    export TF_VAR_project_id=$PROJECT_ID
    terraform init
    terraform plan
    terraform apply
    ```
   NOTE: if you get an error due to default network not being present, run `gcloud compute networks create default --subnet-mode=auto` and retry the commands.

1. To verify things have sync'ed, you can use `gcloud` to check status:

    ```bash
    gcloud alpha container hub config-management status --project $PROJECT_ID
    ```

    In the output, notice that the `Status` will eventually show as `SYNCED` and the `Last_Synced_Token` will match the repo hash.

1. To see wordpress itself, you can use the kubectl proxy to connect to the service:

    ```bash
    # get values from cluster that was created


    # then get credentials for it and proxy to the wordpress service to see it running
    gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID
    kubectl proxy --port 8888 &

    # curl or use the browser
    curl http://127.0.0.1:8888/api/v1/namespaces/wp/services/wordpress/proxy/wp-admin/install.php

    ```

1. To see is GKE clusters have been successfully created.


    ```bash   
    gcloud container clusters list

     NAME              LOCATION  MASTER_VERSION   MASTER_IP    MACHINE_TYPE  NODE_VERSION     NUM_NODES  STATUS
     gke-cluster-east  us-east1  1.22.6-gke.1000  xx.xx.xx.xx  e2-medium     1.22.6-gke.1000  6          RECONCILING
     gke-cluster-west  us-west1  1.22.6-gke.300   xx.xx.xx.xx  e2-medium     1.22.6-gke.300   6          RECONCILING

    ```

1. To see is Anthos Config Management feature has been activate successfully.


    ```bash
       
    gcloud container hub memberships list

    NAME                             EXTERNAL_ID
    membership-hub-gke-cluster-east  xxxx-xxxx-xxxx-xxxx
    membership-hub-gke-cluster-west  xxxx-xxxx-xxxx-xxxx

    ```

1. To see is Anthos Service Mesh feature has been activate successfully.

 # First lets get the credentials for the GKE cluster 
    gcloud container clusters get-credentials gke-cluster-east --region "us-east1" --project $PROJECT_ID


    # Inspect the state of controlplanerevision CustomResource
    kubectl describe controlplanerevision asm-managed -n istio-system
    
    The output is similar to the following:


        Name:         asm-managed
        Namespace:    istio-system
        Labels:       mesh.cloud.google.com/managed-cni-enabled=true
        Annotations:  <none>
        API Version:  mesh.cloud.google.com/v1beta1
        Kind:         ControlPlaneRevision
        Metadata:
        Creation Timestamp:  2022-02-04T19:10:56Z
        Generation:          1
        Managed Fields:
            API Version:  mesh.cloud.google.com/v1beta1
            Fields Type:  FieldsV1
            fieldsV1:
            f:metadata:
                f:annotations:
                .:
                f:kubectl.kubernetes.io/last-applied-configuration:
                f:labels:
                .:
                f:mesh.cloud.google.com/managed-cni-enabled:
            f:spec:
                .:
                f:channel:
                f:type:
            Manager:      kubectl-client-side-apply
            Operation:    Update
            Time:         2022-02-04T19:10:56Z
            API Version:  mesh.cloud.google.com/v1alpha1
            Fields Type:  FieldsV1
            fieldsV1:
            f:status:
                .:
                f:conditions:
            Manager:         Google-GKEHub-Controllers-Servicemesh
            Operation:       Update
            Time:            2022-02-04T19:12:50Z
        Resource Version:  14573
        UID:               2b7d5d2c-438d-4a14-9c62-625545ac80d7
        Spec:
        Channel:  regular
        Type:     managed_service
        Status:
        Conditions:
            Last Transition Time:  2022-02-04T19:18:04Z
            Message:               The provisioning process has completed successfully
            Reason:                Provisioned
            Status:                True
            Type:                  Reconciled
            Last Transition Time:  2022-02-04T19:18:04Z
            Message:               Provisioning has finished
            Reason:                ProvisioningFinished
            Status:                True
            Type:                  ProvisioningFinished
            Last Transition Time:  2022-02-04T19:18:04Z
            Message:               Provisioning has not stalled
            Reason:                NotStalled
            Status:                False
            Type:                  Stalled
        Events:                    <none>

    
    # Review the status of the controlplanerevision custom resource named asm-managed, the RECONCILED field should be set to True.
    kubectl get controlplanerevisions -n istio-system

    The output is similar to the following:


            NAME          RECONCILED   STALLED   AGE
            asm-managed   True         False     14m

    # Review the configmaps in the istio-system namespace.

    kubectl get configmaps -n istio-system

    The output is similar to the following:


        NAME                   DATA   AGE
        asm-options            1      20m
        env-asm-managed        3      8m2s
        istio-asm-managed      1      20m
        istio-gateway-leader   0      8m1s
        istio-leader           0      8m1s
        kube-root-ca.crt       1      20m
        mdp-eviction-leader    0      12m

    ```

1. To see is Config connector has been activate successfully.


```bash

kubectl wait -n cnrm-system --for=condition=Ready pod --all
pod/cnrm-deletiondefender-0 condition met
pod/cnrm-resource-stats-recorder-85c5876968-kmvdn condition met
pod/cnrm-webhook-manager-d48686cb-5k8x4 condition met
pod/cnrm-webhook-manager-d48686cb-hpthv condition met

```


1. To see is Policy Controller has been activate successfully.

```bash

gcloud beta container hub config-management status --project $PROJECT_ID

#You should see output similar to the following example:
Name                             Status  Last_Synced_Token  Sync_Branch  Last_Synced_Time      Policy_Controller 
membership-hub-gke-cluster-east  SYNCED  xxxxxxxxx          master       2022-03-01T02:47:16Z  INSTALLED          
membership-hub-gke-cluster-west  SYNCED  xxxxxxxx           master       2022-03-01T02:47:10Z  INSTALLED        

```

1. To see is Cloud  Build trigger has been created successfully.

```bash

gcloud beta builds triggers list
---
createTime: '2022-03-01T02:24:20.772661279Z'
filename: cloudbuild.yaml
id: xxxx-xxx-xxx-xxx-xxxx
name: trigger
serviceAccount: projects/xxx-xx-xx/serviceAccounts/xx-xxx-account@xxx-xx-xx.iam.gserviceaccount.com
triggerTemplate:
  branchName: master
  projectId: xxx-xxx-xx
  repoName: https://github.com/IshmeetMehta/container-app

```

1. Finally, let's clean up. First, don't forget to foreground the proxy again to kill it. Also, apply `terraform destroy` to remove the GCP resources that were deployed to the project.

   ```bash
    fg # ctrl-c

    # Disable the mesh api 
    gcloud container hub mesh disable --project=$PROJECT_ID

    terraform destroy -var=project=$PROJECT_ID
    ```
