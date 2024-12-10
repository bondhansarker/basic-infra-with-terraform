output "connection_name" {
  description = "The connection name of the database instance"
  value       = data.google_sql_database_instance.this.connection_name
}

output "private_ip_address" {
  description = "The IP address of the database instance"
  value       = data.google_sql_database_instance.this.private_ip_address
}