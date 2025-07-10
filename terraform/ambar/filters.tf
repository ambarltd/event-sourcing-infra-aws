# This is a default filter we will apply for all destinations which will forward all events. This means each endpoint
# of the backend application will see every event ever created. If you want to have more narrow filters create a new
# one following https://docs.ambar.cloud/ and apply it to destinations as desired.
resource "ambar_filter" "all_events" {
  data_source_id  = ambar_data_source.event_store.resource_id
  description     = "All DataSource events"
  filter_contents = "true"
}