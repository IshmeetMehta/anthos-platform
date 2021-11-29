resource "null_resource" "previous" {}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [null_resource.previous]

  create_duration = "120s"
}

module "enabled_google_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 10.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "anthosconfigmanagement.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sqladmin.googleapis.com"
  ]
  depends_on = [time_sleep.wait_120_seconds]
}


module "gke" {
  depends_on                        = [module.vpc.subnets_names]
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
  # network                           = module.vpc.network_name.
  # subnetwork                        = module.vpc.subnet_name[each.value.subnet_name]
  # ip_range_pods                     = module.vpc.secondary_ranges_pods_name[each.value.secondary_ranges_pods_name]
  # ip_range_services                 = module.vpc.secondary_ranges_services_name[each.value.secondary_ranges_services_name]
  # enable_private_endpoint           = false
  # enable_private_nodes              = false
  # master_ipv4_cidr_block            = " "
  # network_policy                    = true
  # horizontal_pod_autoscaling        = true
  # service_account                   = "create"
  # remove_default_node_pool          = true
  # disable_legacy_metadata_endpoints = true

  # master_authorized_networks = [
  #   {

  #   },
  # ]

  node_pools = [
    {
      name               = "my-node-pool"
      machine_type       = "n1-standard-1"
      min_count          = 1
      max_count          = 4
      # disk_size_gb       = 100
      # disk_type          = "pd-ssd"
      # image_type         = "COS"
      # auto_repair        = true
      # auto_upgrade       = false
      # preemptible        = false
      # initial_node_count = 1
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

