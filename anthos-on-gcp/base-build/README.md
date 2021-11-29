# Build Anthos Application Development platform with all feature and components on Google Cloud Platform

# Pre-requistes

1. Install Google Cloud SDK
2. Install Terraform
3. Active Anthos trial license

## Steps to deploy the platform:

Components and features : Google Kubernetes Engine, Anthos Config Management, Anthos Config Connector, 

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


    # then get creditials for it and proxy to the wordpress service to see it running
    gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID
    kubectl proxy --port 8888 &

    # curl or use the browser
    curl http://127.0.0.1:8888/api/v1/namespaces/wp/services/wordpress/proxy/wp-admin/install.php

    ```

1. Finally, let's clean up. First, don't forget to foreground the proxy again to kill it. Also, apply `terraform destroy` to remove the GCP resources that were deployed to the project.

   ```bash
    fg # ctrl-c

    terraform destroy -var=project=$PROJECT_ID
    ```
