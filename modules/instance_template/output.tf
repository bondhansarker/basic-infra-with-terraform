output "self_link" {
  description = "Link to the instance template"
  value       = google_compute_region_instance_template.this.self_link
}

output "id" {
  description = "ID to the instance template"
  value       = google_compute_region_instance_template.this.id
}