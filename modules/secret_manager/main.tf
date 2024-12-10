# Create the secrets in Secret Manager
resource "google_secret_manager_secret" "this" {
  provider = google-beta
  for_each = var.secrets

  secret_id = each.key
  replication {
    auto {}
  }
}

# Create secret versions
resource "google_secret_manager_secret_version" "this" {
  provider = google-beta
  for_each = google_secret_manager_secret.this

  secret      = each.value.id
  secret_data = var.secrets[each.value.secret_id]
  enabled     = true
}