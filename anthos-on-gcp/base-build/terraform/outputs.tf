
output "cluster_location" {
  value = module.gke["us-east1"].location
}

output "cluster_name" {
  value = module.gke["us-east1"].name
}

output "us-east_cluster_endpoint" {
  value = module.gke["us-east1"].endpoint
  sensitive = true
}

output "us-east_ca_certificate" {
  value = module.gke["us-east1"].ca_certificate
  sensitive = true
}

