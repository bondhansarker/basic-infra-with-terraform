# Terraform Configuration

This repository contains Terraform configurations for managing infrastructure in Google Cloud Platform (GCP). It supports multiple environments and includes configurations for SQL instances, networking, scalable frontend and backend services, secret management, and more.

## Repository Structure

```
Root
│
├── main.tf               # Main configuration file for SQL, network, services, etc.
├── variables.tf          # Variable definitions for the Terraform configuration
├── outputs.tf            # Output definitions for the Terraform configuration
│
├── services              # Directory containing service configurations for Access and Dashboard
│   ├── access            # Business-specific configurations for the Access service
│   └── dashboard         # Business-specific configurations for the Dashboard service
│
├── modules               # Directory containing reusable Terraform modules
│   ├── instance_template
│   ├── instance_group
│   ├── loadbalancer
│   ├── health_check
│   ├── network
│   ├── firewall
│   ├── cloud_function
│   ├── secret_manager
│   └── sql_instance
│
└── environments          # Directory containing environment-specific configurations
    ├── dev.terraform.tfvars
    └── prod.terraform.tfvars
```

## Setup and Usage

1. **Initialize Terraform**

   Before applying any configurations, initialize the Terraform working directory:

   ```bash
   terraform init
   ```
2. **Backend Configuration for Remote State**

   This configuration uses a remote backend on Google Cloud Storage (GCS) to store Terraform state files. This ensures state consistency and allows for collaboration across teams.

   ```hcl
   backend "gcs" {
     bucket  = "bucket-name-for-state-files"
     prefix  = "terraform/state"
   }
   ```

   The backend will store the Terraform state file in a GCS bucket named `bucket-name-for-state-files` with the prefix `terraform/state`. This allows you to manage multiple environments and resources without conflicts, ensuring that all Terraform operations read and write from the same state file.

3. **Fetching Remote State Data**

   You can fetch data from the remote state using the `terraform_remote_state` data source. For example:

   ```hcl
   data "terraform_remote_state" "foo" {
     backend = "gcs"
     config = {
       bucket  = "bucket-name-for-state-files"
       prefix  = "dev"
     }
   }
   ```

   This configuration allows you to access the state file stored in the `dev` environment. You can use this data in other configurations to reference resources created in the `dev` state.

4. **Create a Terraform Workspace**

    Create a Terraform workspace for each environment:
    
    ```bash
    terraform workspace new dev
    terraform workspace new prod
    ```
    
    To switch between workspaces:
    
    ```bash
    terraform workspace select dev
    terraform workspace select prod
    ```
    
    To list all workspaces:
    
    ```bash
    terraform workspace list
    ```
5. **Create a Terraform Variable File**

   The `environments` directory contains environment-specific `.tfvars` files, such as `dev.terraform.tfvars` and `prod.terraform.tfvars`. These files define variable values for each environment. Example:

   ```hcl
   project_id   = "my-project"
   environment  = "dev"
   region       = "us-central1"
   subnet_name  = "my-subnet"
   # Add other variables as needed
   ```

6. **Apply Configuration**
   
Before applying the full Terraform configuration, ensure that your artifact repositories, buckets, and network components (such as VPC, subnet, static IPs, VPC connector, global private network, and NAT router) are either created or already exist. If these resources do not exist, you can use the respective `create_*` flags (e.g., `create_network=true`). For existing resources, set the fields to an empty string (`""`).

The Terraform apply procedure should follow these steps:

   **Create or Ensure Networks**

   First, create the network components (or ensure they exist):

   ```bash
   terraform apply -target module.network --var-file=environments/dev.terraform.tfvars
   ```

   After the network is configured, create the other resources in one go:

   ```bash
   terraform apply --var-file=environments/dev.terraform.tfvars
   ```

 **Verify the Setup**

   Once everything is applied, check the Terraform output for the service IPs. Your app should now be ready for use.
   ```bash
   terraform output
   ```

## Directory Details

- **Root Directory**: Contains the primary Terraform files (`main.tf`, `variables.tf`, `outputs.tf`) that define the infrastructure for SQL, networking, and services.

- **services Directory**: Contains business-specific configurations for `access` and `dashboard`. Each service uses similar Terraform modules with different parameters and startup scripts tailored to their respective business logic.

- **modules Directory**: Contains reusable Terraform modules, such as:
   - `instance_template`
   - `instance_group`
   - `loadbalancer`
   - `health_check`
   - `network`
   - `firewall`
   - `cloud_function`
   - `secret_manager`
   - `sql_instance`

- **environments Directory**: Contains environment-specific variable files such as `dev.terraform.tfvars` and `prod.terraform.tfvars` to manage different configurations across environments.

## Multiple Environment Support

The configuration supports multiple environments by utilizing different `.tfvars` files in the `environments` directory. This allows for environment-specific configurations (e.g., dev, staging, prod).

In addition, a remote backend on Google Cloud Storage (GCS) manages state files separately for each environment. This setup ensures consistent state management, enabling smooth collaboration and organization across different environments.
## Service-Specific Customization

Both `access` and `dashboard` services use similar modules but differ in:
- Business-specific parameters
- Separate startup scripts based on their function and role

## Contributing

Feel free to submit issues or pull requests to improve the Terraform configurations. Please test changes in a non-production environment before merging into the main branch.
