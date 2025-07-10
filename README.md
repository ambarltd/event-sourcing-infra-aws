# Event Sourcing Application Template

A comprehensive template repository for building event sourcing applications on AWS using modern cloud-native services and infrastructure as code.

## Overview

This template provides a complete foundation for event sourcing applications with the following architecture:

- **Event Storage**: Event streams stored in AWS RDS (PostgreSQL)
- **Event Transmission**: Ambar Cloud service integration for event streaming
- **Event Processing**: Containerized Cluster Services running on AWS ECS
- **Projection Storage**: Read models are projected into MongoDB Atlas
- **Infrastructure**: Fully automated deployment using Terraform
- **Monitoring**: CloudWatch integration for logging and metrics
- **Networking**: Secure VPC configuration with proper subnet isolation

It creates all the necessary infrastructure and provides details to the application for connections and configuration via
environment variables on containers.

## Architecture Components

- **AWS RDS (PostgreSQL)**: Primary event store
- **MongoDB Atlas**: Document store for projections
- **AWS ECS**: Container orchestration for application services
- **AWS S3**: Static assets, backups, and artifact storage
- **AWS ECR**: Private container registry
- **AWS VPC**: Network isolation and security
- **AWS CloudWatch**: Centralized logging and monitoring
- **Ambar Cloud**: Event stream transmission

## Prerequisites

Before using this template, ensure you have:

- AWS CLI installed and configured
- Terraform >= 1.5.0 installed (for local development)
- Docker installed (for local development)
- Git configured
- A GitHub account with Actions enabled
- MongoDB Atlas credentials (Private and Public keys)
- Ambar Cloud API Key (For region desired)

## Getting Started

### 1. Create Repository from Template

1. Click "Use this template" to create a new repository
2. Clone your new repository locally
3. Follow the setup steps below

### 2. Terraform prerequisite AWS Infrastructure Setup

#### Configure AWS Credentials

First, ensure your AWS CLI is configured with appropriate permissions:

```bash
aws configure
```

#### Create Terraform State Management Resources

Create an S3 bucket for Terraform state storage:

```bash
# Replace 'your-unique-bucket-name' with a globally unique name
export TF_STATE_BUCKET="your-project-terraform-state-$(date +%s)"
export AWS_REGION="eu-west-1"  # Change to your preferred region

# Create S3 bucket for state storage
aws s3api create-bucket \
    --bucket $TF_STATE_BUCKET \
    --region $AWS_REGION

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
    --bucket $TF_STATE_BUCKET \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
    --bucket $TF_STATE_BUCKET \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'
```

Create a DynamoDB table for state locking:

```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $AWS_REGION
```

### 3. GitHub Actions Configuration

#### Required Secrets

Add the following secrets to your GitHub repository (`Settings > Secrets and variables > Actions > Secrets`):

```bash
# AWS Credentials for GitHub Actions
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key

# Ambar Cloud API Key
AMBAR_API_KEY=your-ambar-api-key

# MongoDB Atlas Credentials
MONGODB_PRIVATE_KEY=your-mongodb-private-key
MONGODB_PUBLIC_KEY=your-mongodb-public-key
```

#### Required Variables

Add the following variables to your GitHub repository (`Settings > Secrets and variables > Actions > Variables`):

```bash
# Terraform State Configuration
TF_STATE_BUCKET=your-terraform-state-bucket-name
TF_STATE_DYNAMODB_TABLE=terraform-state-lock
AWS_REGION=eu-west-1

# Ambar Cloud Configuration
AMBAR_API_ENDPOINT=euw1.api.ambar.cloud

# MongoDB Atlas Configuration
MONGODB_PROJECT_ID=your-mongodb-project-id
MONGODB_CLUSTER_NAME=your-cluster-name
```

### 4. Third-Party Service Setup

#### MongoDB Atlas

1. Create a MongoDB Atlas account at https://cloud.mongodb.com
2. Create a new project
3. Generate API keys:
   ```bash
   # In MongoDB Atlas Console:
   # 1. Go to Access Manager > Organization Access > API Keys
   # 2. Create API Key with "Organization Project Creator" permissions
   # 3. Note down the Public Key and Private Key
   ```
4. Add your public key and private key to GitHub secrets as shown above

#### Ambar Cloud

1. Sign up for Ambar Cloud service at https://portal.ambar.cloud/
2. Create a new environment (Enterprise or Startup)
3. Add your API key to the GitHub secrets as shown above


#### Application Configuration

See modules.tf locals section where there is a map for further custom frontend and backend application environment variables.
Either include them directly via the locals or by passing them from a github value.

### 5. Deploy Infrastructure

Once all prerequisites are configured, deploy using GitHub Actions:

#### Evaluate Changes:

1. Create changes in new branch
2. Push branch to remote and create pull-request
3. Allow actions to complete and evaluate terraform changes are as expected

#### Deploy Changes:

1. Merge changes to the `main` branch
2. Go to the Actions tab in your GitHub repository
3. Monitor the deployment progress

### 6. Deploy Application

Todo: This section

## Project Structure

Todo: This sectionm

```
├── terraform/              # Infrastructure as Code
│   ├── modules/            # Reusable Terraform modules
│   ├── environments/       # Environment-specific configurations
│   └── main.tf            # Main Terraform configuration
├── src/                    # Application source code
│   ├── events/            # Event definitions and handlers
│   ├── projections/       # Read model projections
│   └── services/          # Application services
├── docker/                 # Docker configurations
├── .github/               # GitHub Actions workflows
│   └── workflows/
├── docs/                  # Additional documentation
└── scripts/               # Utility scripts
```

## Development Workflow

1. **Feature Branches**: Create feature branches for new development
2. **Pull Requests**: All changes must go through PR review
3. **Automated Testing**: Tests run automatically on PR creation
4. **Deployment**: Merge to `main` triggers automatic deployment

## Monitoring and Logging

- **CloudWatch Logs**: Application logs are automatically forwarded
- **CloudWatch Metrics**: Custom metrics for business events
- **Health Checks**: Automated health monitoring for all services
- **Alerts**: Configurable alerts for critical system events

## Security Considerations

- All secrets are stored in GitHub Secrets or AWS Parameter Store
- VPC provides network isolation
- Security groups restrict access to necessary ports only
- IAM roles follow principle of least privilege
- All S3 buckets have encryption enabled

## Support and Documentation

- See `docs/` directory for detailed documentation
- Check GitHub Issues for known problems
- Review CloudWatch logs for troubleshooting
