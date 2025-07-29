# We create all destinations with the all_events filter. If you need finer grained event filtering on some or all endpoints
# define new filters and a destination for each endpoint.
resource "ambar_data_destination" "destination" {
  for_each = { for idx, destination in var.destination_endpoints_to_descriptions : idx => destination }

  filter_ids = [
    var.filter_id,
  ]

  description          = each.value.description
  destination_endpoint = "https://${var.data_destination_domain}/${each.value.path}"

  username = var.ambar_username
  password = var.ambar_password
}