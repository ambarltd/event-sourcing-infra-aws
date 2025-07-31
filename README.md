# Ambar AWS Event Sourcing Application Terraform Module

A comprehensive Terraform module for deploying event sourcing applications on AWS using modern cloud-native services and infrastructure as code.

## Overview

This Terraform module provides a complete infrastructure foundation for event sourcing applications. It creates and manages all necessary AWS resources, third-party integrations, and networking components required for a production-ready event sourcing architecture.

### Infrastructure Components

The module creates the following infrastructure:

- **VPC & Networking**: Secure VPC with public/private subnets across multiple AZs, security groups, and internet gateway
- **Event Store**: AWS RDS PostgreSQL database for event stream storage with automated backups
- **Projection Store**: MongoDB Atlas cluster for read model projections with connection credentials
- **Container Services**: AWS ECS clusters with ALB/NLB for frontend and backend services
- **Container Registry**: AWS ECR repositories with GitHub OIDC integration for CI/CD
- **Object Storage**: S3 buckets for static assets with lifecycle policies and versioning
- **Email Service**: AWS SES with domain verification, DKIM, and SMTP credentials
- **Domain Management**: Route53 hosted zone with DNS records for domain setup
- **Event Streaming**: Ambar Cloud integration for real-time event transmission
- **Monitoring**: CloudWatch logs, metrics, and SNS alerts for system monitoring

### Module Usage

#### Example 1: Minimal Required Configuration

```hcl
module "event_sourcing_app" {
  source = "github.com/ambarltd/event-sourcing-infra-aws.git"

  # Required AWS Configuration
  region = "us-east-1"

  # Required MongoDB Atlas Configuration
  mongodbatlas_project_id = "507f1f77bcf86cd799439011"

  # Required Ambar Configuration
  destination_endpoints_to_descriptions = [
    {
      path        = "/projections/users"
      description = "User projection endpoint"
    },
    {
      path        = "/projections/orders"  
      description = "Order projection endpoint"
    }
  ]

  # Required Domain Configuration
  top_level_domain                        = "example.com"
  backend_application_domain_prefix       = "api" # Becomes api.example.com
  from_email                             = "notifications@example.com"
  hosted_zone_id                         = "Z1D633PJN98FT9"
  hosted_zone_name                       = "example.com"

  # Required GitHub Integration
  github_organization_with_read_write_access     = "myorg"
  frontend_github_repository_with_read_write_access = "frontend-app"
  frontend_github_branch_with_read_write_access     = "main"
  backend_github_repository_with_read_write_access  = "backend-api"
  backend_github_branch_with_read_write_access      = "main"

  # Required Application Images
  frontend_image = "some-git-hash"
  backend_image  = "some-git-hash"

  # Required Application Configuration
  ## Frontend
  frontend_application_port = 8080
  frontend_cpu_capacity     = 256
  frontend_mem_capacity     = 512
  frontend_instance_count   = 1
  ## Backend
  backend_application_port  = 3000
  backend_cpu_capacity      = 512
  backend_mem_capacity      = 1024
  backend_instance_count    = 1

  # Required Monitoring Configuration
  emails_for_alerts = ["admin@example.com"]

  # Required Deployment Management
  # Event store should be configured manually or by your application before ambar resources are configured.
  event_store_configured = false
  environment_name       = "production"
}
```

#### Example 2: Full Configuration with All Parameters (Defaults Shown)

```hcl
module "event_sourcing_app" {
  source = "github.com/ambarltd/event-sourcing-infra-aws.git"

  # Required AWS Configuration
  region = "us-east-1"

  # Required MongoDB Atlas Configuration
  mongodbatlas_project_id = "507f1f77bcf86cd799439011"
  mongodbatlas_free_tier  = false  # default: false

  # Required Ambar Configuration
  destination_endpoints_to_descriptions = [
    {
      path        = "/projections/users"
      description = "User projection endpoint"
    },
    {
      path        = "/projections/orders"
      description = "Order projection endpoint"
    },
    {
      path        = "/reactions/notifications"
      description = "Notification reaction endpoint"
    },
    {
      path        = "/reactions/email-triggers"
      description = "Email trigger reaction endpoint"
    }
  ]

  # Required Domain Configuration
  top_level_domain                        = "example.com"
  frontend_application_domain_prefix      = ""
  backend_application_domain_prefix       = "api"
  from_email                             = "notifications"
  hosted_zone_id                         = "Z1D633PJN98FT9"
  hosted_zone_name                       = "example.com"

  # Required GitHub Integration
  github_organization_with_read_write_access           = "myorg"
  frontend_github_repository_with_read_write_access    = "frontend-app"
  frontend_github_branch_with_read_write_access        = "main"  # default: "main"
  backend_github_repository_with_read_write_access     = "backend-api"
  backend_github_branch_with_read_write_access         = "main"  # default: "main"

  # Required Application Images
  frontend_image = "a6c58d7df3ea76c5463161eae6c201659e397ece"
  backend_image  = "a6c58d7df3ea76c5463161eae6c201659e397ece"

  # Required Frontend Configuration
  frontend_application_port = 8080
  frontend_cpu_capacity     = 256
  frontend_mem_capacity     = 512
  frontend_instance_count   = 1
  additional_frontend_domains = []  # default: []
  frontend_environment_variables = []  # default: []

  # Required Backend Configuration
  backend_application_port = 3000
  backend_cpu_capacity     = 512
  backend_mem_capacity     = 1024
  backend_instance_count   = 1
  backend_environment_variables = []  # default: []

  # Required Monitoring Configuration
  emails_for_alerts = ["admin@example.com", "ops@example.com"]

  # Required Deployment Management
  event_store_configured = false  # default: false (set to true after first deployment)
  environment_name       = "production"
}
```

## Event Store Configuration & Ambar Integration

The infrastructure automatically configures a complete PostgreSQL event store with full Ambar integration for real-time event streaming. This provides a production-ready event sourcing foundation with zero manual configuration required.

### Automatic Configuration

The event store module automatically creates and configures:

#### 1. Database Schema
- **Events Table**: `event_store` with schema matching your Java application exactly:
  - `id` (BIGSERIAL, primary key) - Serial column for Ambar record ordering
  - `event_id` (TEXT, UNIQUE) - Unique event identifier
  - `event_name` (TEXT) - Event type name for filtering
  - `aggregate_id` (TEXT) - Aggregate identifier for queries
  - `aggregate_version` (BIGINT) - Version for optimistic concurrency control
  - `json_payload` (TEXT) - Event data as JSON string
  - `json_metadata` (TEXT) - Event metadata as JSON string
  - `recorded_on` (TEXT) - Event timestamp as string
  - `causation_id` (TEXT) - Causation tracking for event chains
  - `correlation_id` (TEXT) - **Partitioning column for Ambar streaming**

#### 2. Performance Indexes & Constraints
- **UNIQUE indexes** for data integrity:
  - `event_store_idx_event_aggregate_id_version` on (aggregate_id, aggregate_version)
  - `event_store_idx_event_id` on (event_id)
- **Performance indexes** for fast queries:
  - `event_store_idx_event_causation_id` on (causation_id)
  - `event_store_idx_event_correlation_id` on (correlation_id) - **Critical for Ambar**
  - `event_store_idx_occurred_on` on (recorded_on)
  - `event_store_idx_event_name` on (event_name)

#### 3. Ambar Streaming Configuration
- **Replication User**: Dedicated user with `REPLICATION` privileges for Ambar
- **Database Privileges**: `CONNECT` and `SELECT` privileges on event store
- **Logical Replication Publication**: `ambar_publication` configured for streaming
- **Replication Slot**: `ambar_event_store_slot` for reliable, ordered event delivery
- **Data Source**: Automatically configured Ambar data source pointing to your event store

### Application Requirements

To work correctly with the pre-configured event store and Ambar streaming, your application must:

#### 1. Follow the Exact Schema
```javascript
// ✅ Correct: Use the exact column names and data types
const event = {
  event_id: uuidv4(),                    // TEXT (unique)
  event_name: 'UserCreated',             // TEXT 
  aggregate_id: userId,                  // TEXT
  aggregate_version: 1,                  // BIGINT (number)
  json_payload: JSON.stringify(data),    // TEXT (JSON as string)
  json_metadata: JSON.stringify(meta),   // TEXT (JSON as string)
  recorded_on: new Date().toISOString(), // TEXT (ISO string)
  causation_id: causationId,             // TEXT
  correlation_id: correlationId          // TEXT (REQUIRED for Ambar)
};
```

#### 2. Ensure Correlation ID Consistency
The `correlation_id` field is **critical for Ambar partitioning**:
- **Must be consistent** for related events that should be processed in order
- **Should be different** for events that can be processed in parallel
- **Cannot be null** - Ambar uses this for data distribution

#### 3. Use Append-Only Pattern
- **Never UPDATE or DELETE** events once written (Ambar requirement)
- **Only INSERT** new events to maintain streaming consistency
- Use **aggregate_version** for optimistic concurrency control

#### 4. Handle Environment Variables
Your application receives these automatically configured variables:

```javascript
// Database connection
const eventStore = new EventStore({
  host: process.env.EVENT_STORE_HOST,
  port: process.env.EVENT_STORE_PORT,
  database: process.env.EVENT_STORE_DATABASE_NAME,
  username: process.env.EVENT_STORE_USER,
  password: process.env.EVENT_STORE_PASSWORD
});

// Table names (use these constants)
const EVENTS_TABLE = process.env.EVENT_STORE_EVENTS_TABLE_NAME; // 'event_store'
```

### Real-Time Event Streaming

Once configured, Ambar automatically streams events to your application endpoints:

#### 1. Automatic Event Detection
- **New events** in the `event_store` table are automatically detected
- **Ordered delivery** based on the `id` column (serial)
- **Partitioned delivery** based on `correlation_id` for parallel processing

#### 2. Destination Endpoints
Events are streamed to your configured endpoints:
```javascript
// Your application should handle these HTTP POST requests
app.post('/projections/users', (req, res) => {
  const { events } = req.body; // Array of new events
  // Update your read models/projections
});

app.post('/reactions/notifications', (req, res) => {
  const { events } = req.body; // Array of new events  
  // Trigger side effects (emails, notifications, etc.)
});
```

### Deployment Process

1. **Deploy Infrastructure**: Event store and Ambar are automatically configured
2. **Deploy Application**: Use provided environment variables to connect
3. **Start Writing Events**: Events are immediately streamed to your endpoints
4. **Monitor Streaming**: Use CloudWatch and Ambar monitoring for observability

### Best Practices

#### Event Design
- **Include correlation_id** in every event for proper partitioning
- **Use meaningful event_name** values for filtering and monitoring
- **Store rich data** in json_payload for projection building
- **Include causation_id** for tracing event chains

#### Error Handling
- **Handle duplicate events** (Ambar provides at-least-once delivery)
- **Implement idempotency** in your event handlers
- **Use exponential backoff** for transient failures

#### Monitoring
- **Monitor replication lag** via CloudWatch metrics
- **Track event processing** in your application endpoints
- **Set up alerts** for streaming failures

### PostgreSQL Configuration
- **Version**: PostgreSQL 15.10 (Aurora) with logical replication enabled
- **Parameters**: All Ambar-required parameters automatically configured
- **Security**: TLS encryption enforced, dedicated replication user
- **Backup**: Automated backups and point-in-time recovery enabled

The event store is production-ready and requires no manual configuration. Your application can immediately start writing events and receiving real-time streams through Ambar.

For advanced configuration and troubleshooting, refer to the [Ambar Documentation](https://docs.ambar.cloud/).

## Requirements

| Name | Version   |
|------|-----------|
| [terraform](#requirement\_terraform) | >= 1.0.0  |
| [aws](#requirement\_aws) | 5.90.0*   |
| [random](#requirement\_random) | >= 3.1.0  |
| [mongodbatlas](#requirement\_mongodbatlas) | >= 1.4.0  |
| [ambar](#requirement\_ambar) | >= 1.0.11 |
| [postgresql](#requirement\_postgresql) | >= 1.15.0 |

*AWS Version currently pinned due to issues with ap-southeast-5 and other regions.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy resources | `string` | n/a | yes |
| <a name="input_mongodbatlas_project_id"></a> [mongodbatlas\_project\_id](#input\_mongodbatlas\_project\_id) | MongoDB Atlas Project Identifier | `string` | n/a | yes |
| <a name="input_mongodbatlas_free_tier"></a> [mongodbatlas\_free\_tier](#input\_mongodbatlas\_free\_tier) | If the projection store should use the M0 or M10 cluster size | `bool` | `false` | no |
| <a name="input_destination_endpoints_to_descriptions"></a> [destination\_endpoints\_to\_descriptions](#input\_destination\_endpoints\_to\_descriptions) | List of destinations objects describing endpoint path and a description | `list(object({path=string, description=string}))` | n/a | yes |
| <a name="input_github_organization_with_read_write_access"></a> [github\_organization\_with\_read\_write\_access](#input\_github\_organization\_with\_read\_write\_access) | The github organization name | `string` | n/a | yes |
| <a name="input_frontend_github_repository_with_read_write_access"></a> [frontend\_github\_repository\_with\_read\_write\_access](#input\_frontend\_github\_repository\_with\_read\_write\_access) | The name of the github repo which contains the source for your frontend application | `string` | n/a | yes |
| <a name="input_frontend_github_branch_with_read_write_access"></a> [frontend\_github\_branch\_with\_read\_write\_access](#input\_frontend\_github\_branch\_with\_read\_write\_access) | The name of the deployable github branch for your frontend application | `string` | n/a | yes |
| <a name="input_frontend_image"></a> [frontend\_image](#input\_frontend\_image) | Frontend container image | `string` | n/a | yes |
| <a name="input_frontend_application_port"></a> [frontend\_application\_port](#input\_frontend\_application\_port) | Frontend application port | `number` | n/a | yes |
| <a name="input_frontend_cpu_capacity"></a> [frontend\_cpu\_capacity](#input\_frontend\_cpu\_capacity) | Frontend CPU capacity | `number` | n/a | yes |
| <a name="input_frontend_mem_capacity"></a> [frontend\_mem\_capacity](#input\_frontend\_mem\_capacity) | Frontend memory capacity | `number` | n/a | yes |
| <a name="input_frontend_instance_count"></a> [frontend\_instance\_count](#input\_frontend\_instance\_count) | Frontend instance count | `number` | n/a | yes |
| <a name="input_additional_frontend_domains"></a> [additional\_frontend\_domains](#input\_additional\_frontend\_domains) | Additional frontend domains | `list(string)` | `[]` | no |
| <a name="input_top_level_domain"></a> [top\_level\_domain](#input\_top\_level\_domain) | Domain name for frontend hosting | `string` | n/a | yes |
| <a name="input_frontend_application_domain_prefix"></a> [frontend\_application\_domain\_prefix](#input\_frontend\_application\_domain\_prefix) | A prefix (if any) to apply to the domain for hosting the frontend portion of the application | `string` | `""` | no |
| <a name="input_frontend_environment_variables"></a> [frontend\_environment\_variables](#input\_frontend\_environment\_variables) | Additional environment variables to configure for the service, beside base Ambar configs | `list(object({name=string, value=string}))` | `[]` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | ID of the hosted zone for the domain | `string` | n/a | yes |
| <a name="input_hosted_zone_name"></a> [hosted\_zone\_name](#input\_hosted\_zone\_name) | Name of the hosted zone for the domain | `string` | n/a | yes |
| <a name="input_backend_github_repository_with_read_write_access"></a> [backend\_github\_repository\_with\_read\_write\_access](#input\_backend\_github\_repository\_with\_read\_write\_access) | The name of the github repo which contains the source for your backend application | `string` | n/a | yes |
| <a name="input_backend_github_branch_with_read_write_access"></a> [backend\_github\_branch\_with\_read\_write\_access](#input\_backend\_github\_branch\_with\_read\_write\_access) | The name of the deployable github branch for your backend application | `string` | n/a | yes |
| <a name="input_backend_image"></a> [backend\_image](#input\_backend\_image) | Backend container image | `string` | n/a | yes |
| <a name="input_backend_application_domain_prefix"></a> [backend\_application\_domain\_prefix](#input\_backend\_application\_domain\_prefix) | A prefix (if any) to apply to the domain for hosting the backend portion of the application | `string` | n/a | yes |
| <a name="input_backend_application_port"></a> [backend\_application\_port](#input\_backend\_application\_port) | Backend application port | `number` | n/a | yes |
| <a name="input_backend_cpu_capacity"></a> [backend\_cpu\_capacity](#input\_backend\_cpu\_capacity) | Backend CPU capacity | `number` | n/a | yes |
| <a name="input_backend_mem_capacity"></a> [backend\_mem\_capacity](#input\_backend\_mem\_capacity) | Backend memory capacity | `number` | n/a | yes |
| <a name="input_backend_instance_count"></a> [backend\_instance\_count](#input\_backend\_instance\_count) | Backend instance count | `number` | n/a | yes |
| <a name="input_from_email"></a> [from\_email](#input\_from\_email) | Identity to send emails from the backend as (E.G. 'noreply' for noreply@domain.com) | `string` | n/a | yes |
| <a name="input_backend_environment_variables"></a> [backend\_environment\_variables](#input\_backend\_environment\_variables) | Additional environment variables to configure for the service, beside base Ambar configs | `list(object({name=string, value=string}))` | `[]` | no |
| <a name="input_emails_for_alerts"></a> [emails\_for\_alerts](#input\_emails\_for\_alerts) | List of email addresses for alerts | `list(string)` | n/a | yes |
| <a name="input_event_store_configured"></a> [event\_store\_configured](#input\_event\_store\_configured) | If the application has been deployed at least once and successfully connected to and configured the event store for ambar use | `bool` | n/a | yes |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Resource name prefix for easy identification and allowing multiple template deployments to one AWS account | `string` | n/a | yes |

## Outputs

### Application URLs
| Name | Description |
|------|-------------|
| <a name="output_frontend_url"></a> [frontend\_url](#output\_frontend\_url) | URL of the frontend application |
| <a name="output_backend_url"></a> [backend\_url](#output\_backend\_url) | URL of the backend API |

### Container Registry
| Name | Description |
|------|-------------|
| <a name="output_frontend_ecr_repository_url"></a> [frontend\_ecr\_repository\_url](#output\_frontend\_ecr\_repository\_url) | ECR repository URL for frontend container images |
| <a name="output_frontend_github_assumable_role_read_write"></a> [frontend\_github\_assumable\_role\_read\_write](#output\_frontend\_github\_assumable\_role\_read\_write) | GitHub assumable role for frontend ECR access |
| <a name="output_backend_ecr_repository_url"></a> [backend\_ecr\_repository\_url](#output\_backend\_ecr\_repository\_url) | ECR repository URL for backend container images |
| <a name="output_backend_github_assumable_role_read_write"></a> [backend\_github\_assumable\_role\_read\_write](#output\_backend\_github\_assumable\_role\_read\_write) | GitHub assumable role for backend ECR access |

### Email Service
| Name | Description |
|------|-------------|
| <a name="output_ses_identity"></a> [ses\_identity](#output\_ses\_identity) | SES domain identity ARN for email service |

## Environment Variables

The module automatically configures environment variables for both frontend and backend applications. These variables are injected into the ECS task definitions and are available to your applications at runtime.

### Frontend Application Environment Variables

| Variable Name | Description | Example Value |
|---------------|-------------|---------------|
| `API_ADDRESS` | Backend API endpoint for frontend to connect to | `http://backend-nlb-xxx.amazonaws.com` |
| `PRODUCTION` | Production environment flag | `TRUE` |
| `SERVER_PORT` | Port the frontend server should listen on | `8080` |
| `SERVER_HOSTNAME` | Server hostname binding (IPv6 wildcard) | `::` |
| `DOMAIN` | Comma-separated list of all frontend domains | `app.example.com,www.example.com` |
| `LOAD_BALANCER` | DNS name of the Application Load Balancer | `frontend-alb-xxx.amazonaws.com` |

### Backend Application Environment Variables

#### Event Store Configuration (PostgreSQL RDS)
| Variable Name | Description |
|---------------|-------------|
| `EVENT_STORE_HOST` | RDS PostgreSQL instance endpoint |
| `EVENT_STORE_PORT` | Database connection port (typically 5432) |
| `EVENT_STORE_DATABASE_NAME` | PostgreSQL database name (`postgres`) |
| `EVENT_STORE_USER` | Database authentication username |
| `EVENT_STORE_PASSWORD` | Database authentication password |
| `EVENT_STORE_EVENTS_TABLE_NAME` | Name of the events table (`event_store`) |
| `EVENT_STORE_IDEMPOTENT_REACTION_TABLE_NAME` | Name of the idempotent reactions table (`event_store_idempotent_reaction`) |
| `EVENT_STORE_CREATE_REPLICATION_USER_WITH_USERNAME` | Username for database replication |
| `EVENT_STORE_CREATE_REPLICATION_USER_WITH_PASSWORD` | Password for database replication |
| `EVENT_STORE_CREATE_REPLICATION_PUBLICATION` | Name of the replication publication (`replication_publication`) |

#### MongoDB Projection Store Configuration
| Variable Name | Description |
|---------------|-------------|
| `MONGODB_PROJECTION_HOST` | MongoDB Atlas cluster host |
| `MONGODB_PROJECTION_PORT` | MongoDB connection port (typically 27017) |
| `MONGODB_PROJECTION_AUTHENTICATION_DATABASE` | MongoDB authentication database (`admin`) |
| `MONGODB_PROJECTION_DATABASE_NAME` | MongoDB database for projections (`projections`) |
| `MONGODB_PROJECTION_DATABASE_USERNAME` | MongoDB authentication username |
| `MONGODB_PROJECTION_DATABASE_PASSWORD` | MongoDB authentication password |

#### SMTP Configuration (SES)
| Variable Name | Description |
|---------------|-------------|
| `SMTP_HOST` | SES SMTP endpoint |
| `SMTP_PORT` | SMTP connection port |
| `SMTP_USERNAME` | SES SMTP authentication username |
| `SMTP_PASSWORD` | SES SMTP authentication password |
| `SMTP_FROM_EMAIL_FOR_ADMINISTRATORS` | From email address for administrative emails (`internal@ambar.cloud`) |

#### Ambar Configuration
| Variable Name | Description |
|---------------|-------------|
| `AMBAR_HTTP_USERNAME` | HTTP authentication username for Ambar service (8-character random string) |
| `AMBAR_HTTP_PASSWORD` | HTTP authentication password for Ambar service (16-character random password) |

#### S3 Configuration
| Variable Name | Description |
|---------------|-------------|
| `S3_ENDPOINT_URL` | S3 service endpoint URL |
| `S3_ACCESS_KEY` | S3 authentication access key |
| `S3_SECRET_KEY` | S3 authentication secret key |
| `S3_BUCKET_NAME` | Name of the S3 bucket for blob storage |
| `S3_REGION` | AWS region for S3 operations |

#### Other Configuration
| Variable Name | Description |
|---------------|-------------|
| `FRONTEND_DOMAIN` | Domain name of the frontend application |

### Security Notes

- Sensitive values (passwords, database credentials, API keys) are automatically generated and managed by Terraform
- The Ambar HTTP credentials are randomly generated during deployment for security
- Database and service credentials are sourced from the respective AWS services (RDS, SES, etc.)
