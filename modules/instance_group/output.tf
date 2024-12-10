output "instance_group" {
  description = "Group of the instance group"
  value       = google_compute_region_instance_group_manager.this.instance_group
}
