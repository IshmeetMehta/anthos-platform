resource "google_cloudbuild_trigger" "service-account-trigger" {
  trigger_template {
    branch_name = "master"
    repo_name   = "https://github.com/IshmeetMehta/container-app"
  }

  service_account = google_service_account.cloudbuild_service_account.id
  project = var.project_id
  filename        = "cloudbuild.yaml"
  depends_on = [
    google_project_iam_member.act_as,
    google_project_iam_member.logs_writer
    
  ]
}

resource "google_service_account" "cloudbuild_service_account" {
  account_id = "my-service-account"
  project = var.project_id
}

resource "google_project_iam_member" "act_as" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

resource "google_project_iam_member" "logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}