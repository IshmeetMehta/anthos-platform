resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
   for_each     = var.regions
  
  membership_id = each.value.gke_cluster_hub_membership_id
  #cluster_name = each.value.gke_cluster_name
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke[each.key].cluster_id}"
    }
  }
  depends_on = [module.gke.name, null_resource.enable_mesh ,module.enabled_google_apis.activate_apis] 
}

resource "google_gke_hub_feature" "feature" {
  name = "configmanagement"
  location = "global"

  labels = {
    foo = "bar"
  }
  provider = google-beta
}

resource "google_gke_hub_feature_membership" "feature_member" {
  depends_on = [module.gke.name, module.enabled_google_apis.activate_apis] 
  provider   = google-beta
  location   = "global"
  feature    = "configmanagement"
  for_each   = var.regions
  membership = google_gke_hub_membership.membership[each.key].membership_id
  configmanagement {
    version = "1.8.0"
    config_sync {
      source_format = "unstructured"
      git {
        sync_repo   = var.sync_repo
        sync_branch = var.sync_branch
        policy_dir  = var.policy_dir
        secret_type = "none"
      }
    }
    policy_controller {
      enabled                    = true
      template_library_installed = true
      referential_rules_enabled  = true
    }
  }

}

resource "google_gke_hub_feature" "multiclusterservicediscovery" {
  name = "multiclusterservicediscovery"
  location = "global"
  labels = {
    foo = "bar"
  }
  provider = google-beta
   depends_on = [module.enabled_google_apis.activate_apis]
}

resource "google_gke_hub_feature" "multiclusteringress" {
  name = "multiclusteringress"
  location = "global"
  spec {
    multiclusteringress {
      
      config_membership = "projects/${var.project_id}/locations/global/memberships/membership-hub-gke-cluster-east"
    }
  }
  provider = google-beta
  depends_on = [module.enabled_google_apis.activate_apis, google_gke_hub_feature_membership.feature_member]
}

# google_client_config and kubernetes provider must be explicitly specified like the following.

data "google_client_config" "gke-cluster-east" {
 
}

module "gke_auth" {
  depends_on = [module.gke.name] 
  source           = "terraform-google-modules/kubernetes-engine/google//modules/auth"

  project_id       = module.enabled_google_apis.project_id 
  cluster_name     = module.gke["us-east1"].name
  location         = module.gke["us-east1"].location
}

provider "kubernetes" {

  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  host                   = module.gke_auth.host
  token                  = module.gke_auth.token
}

module "asm" {
  depends_on = [module.enabled_google_apis.activate_apis, module.gke_auth.cluster_name] 
  source           = "git::https://github.com/Monkeyanator/terraform-google-kubernetes-engine.git//modules/asm?ref=rewrite-asm-module"
  cluster_name     = module.gke["us-east1"].name
  cluster_location = module.gke["us-east1"].location
  project_id       = module.enabled_google_apis.project_id  
}