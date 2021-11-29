variable "regions" {
  description = "Regions where GKE cluster needs to be provisioned"
  type =  map(any)
  default = {
    us-east1 = {
      gke_cluster_name = "gke-cluster-east"
      gke_cluster_hub_membership_id = "membership-hub-gke-cluster-east"
      network_name = "us-east-network"
      subnet_name = "us-east-network-subnet"
      subnet_ip = "10.0.0.0/24"
      subnet_region = "us-east1"
      zone = "us-east1-c"
      secondary_ranges_pods_name  = "us-east-pods-range"
      secondary_ranges_pods_ips = "10.1.0.0/16"
      secondary_ranges_services_name  = "us-east-services-range"
      secondary_ranges_services_ips = "10.2.0.0/20"
      },
    us-west1 = {
      gke_cluster_name = "gke-cluster-west"
      gke_cluster_hub_membership_id = "membership-hub-gke-cluster-west"
      network_name = "us-west-network"
      subnet_name = "us-west-network-subnet"
      subnet_ip = "10.0.0.0/24"
      subnet_region = "us-west1"
      zone = "us-west1-c"
      secondary_ranges_pods_name  = "us-west-pods-range"
      secondary_ranges_pods_ips = "10.3.0.0/16"
      secondary_ranges_services_name  = "us-west-services-range"
      secondary_ranges_services_ips = "10.4.0.0/20"
     }
    }
}

module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.5"
  project_id   = var.project_id

  for_each = var.regions
  network_name = each.value.network_name

  subnets = [
    {
      subnet_name   =  each.value.subnet_name 
      subnet_ip     =  each.value.subnet_ip
      subnet_region =  each.value.subnet_region
    },
  ]

  secondary_ranges = {
    (each.value.subnet_name) = [
      {
        range_name    = each.value.secondary_ranges_pods_name
        ip_cidr_range = each.value.secondary_ranges_pods_ips
      },
      {
        range_name    = each.value.secondary_ranges_services_name
        ip_cidr_range = each.value.secondary_ranges_services_ips
      },
  ] }
    depends_on                  = [time_sleep.wait_120_seconds]
}
