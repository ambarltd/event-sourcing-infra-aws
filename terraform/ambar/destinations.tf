# We create all destinations with the all_events filter. If you need finer grained event filtering on some or all endpoints
# define new filters and a destination for each endpoint.
resource "ambar_data_destination" "destination" {
  for_each = var.destination_endpoints_to_descriptions
  filter_ids = [
    ambar_filter.all_events.resource_id,
  ]
  description          = each.value
  destination_endpoint = "https://${var.data_destination_domain}/${each.key}"
  username             = var.ambar_username
  password             = var.ambar_password
}