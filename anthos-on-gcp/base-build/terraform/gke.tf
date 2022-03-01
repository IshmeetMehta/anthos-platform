resource "null_resource" "previous" {}

# resource "time_sleep" "wait_120_seconds" {
#   depends_on = [null_resource.previous]

#   create_duration = "120s"
# }

resource "time_sleep" "wait_120_seconds" {
  depends_on = [null_resource.enable_mesh]

  create_duration = "120s"
}

# TODO: Waiting for fleet api for ASM
resource "null_resource" "enable_mesh" {

  provisioner "local-exec" {
    when    = create
    command = "echo y | gcloud container hub mesh enable --project ${var.project_id}"
  }

  depends_on = [null_resource.previous]
}


module "enabled_google_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 10.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false

   activate_apis = [
    "compute.googleapis.com",
    "anthos.googleapis.com",
    "multiclusteringress.googleapis.com",
    "container.googleapis.com",
    "gkeconnect.googleapis.com", 
    "anthosconfigmanagement.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "multiclusterservicediscovery.googleapis.com",
    "sqladmin.googleapis.com",
    "gkehub.googleapis.com",
    "mesh.googleapis.com",
    "meshconfig.googleapis.com",
    "cloudbuild.googleapis.com"
  ]
}

module "gke" {
  depends_on                        = [module.vpc.subnets_names,module.enabled_google_apis.activate_apis ]
  for_each                          = var.regions
  source                            = "terraform-google-modules/kubernetes-engine/google//modules/beta-public-cluster"
  version                           = "~> 16.0"
  project_id                        = module.enabled_google_apis.project_id
  name                              = each.value.gke_cluster_name
  region                            = each.value.subnet_region
  zones                             = [each.value.zone]
  initial_node_count                = 4
  regional                          = true
  network                           = each.value.network_name
  subnetwork                        = each.value.subnet_name 
  ip_range_pods                     = each.value.secondary_ranges_pods_name
  ip_range_services                 = each.value.secondary_ranges_services_name
  config_connector                  = true

  node_pools = [
    {
      name               = "my-node-pool"
      machine_type       = "n1-standard-1"
      min_count          = 1
      max_count          = 4
    },
  ]

  node_pools_oauth_scopes = {
    all = [

    ]

    my-node-pool = [
 
    ]
  }

  node_pools_labels = {

    all = {

    }
    my-node-pool = {

    }
  }

  node_pools_metadata = {
    all = {}

    my-node-pool = {}

  }

  node_pools_tags = {
    all = []

    my-node-pool = []

  }
}

module "wi" {
  depends_on          = [google_gke_hub_feature_membership.feature_member]
  # depends_on          = [module.gke.cluster_id]
  source              = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  version             = "~> 16.0.1"
  gcp_sa_name         = "cnrmsa-${module.gke[each.key].name}"
  for_each            = var.regions
  cluster_name        = each.value.gke_cluster_name
  name                = "cnrm-controller-manager"
  location            = each.value.zone
  use_existing_k8s_sa = true
  annotate_k8s_sa     = false
  namespace           = "cnrm-system"
  project_id          = module.enabled_google_apis.project_id
  roles               = ["roles/owner"]
}

