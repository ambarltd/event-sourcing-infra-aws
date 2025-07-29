module "destinations" {
  count = var.create_destinations ? 1 : 0

  source = "./destinations"

  ambar_password = var.ambar_password
  ambar_username = var.ambar_username
  data_destination_domain = var.data_destination_domain
  destination_endpoints_to_descriptions = var.destination_endpoints_to_descriptions
  filter_id = ambar_filter.all_events.id
}