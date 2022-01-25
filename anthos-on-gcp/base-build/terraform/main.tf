resource "google_gke_hub_membership" "membership" {
  provider      = google-beta
   for_each     = var.regions
  
  membership_id = each.value.gke_cluster_hub_membership_id
#   cluster_name = each.value.gke_cluster_name
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke[each.key].cluster_id}"
    }
  }
  depends_on = [module.gke.name, module.enabled_google_apis.activate_apis] 
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
  #  for_each   = var.regions
  spec {
    multiclusteringress {
      
      config_membership = "projects/${var.project_id}/locations/global/memberships/membership-hub-gke-cluster-east"
    }
  }
  provider = google-beta
  depends_on = [module.enabled_google_apis.activate_apis, google_gke_hub_feature_membership.feature_member]
}

