# Multi-Tier Web Infrastructure: Terraform, Ansible & Azure Lab

This repository contains an automated Infrastructure-as-Code (IaC) project for deploying a load-balanced web application environment. It utilizes **Terraform** for infrastructure provisioning, **Ansible** for configuration management, and **Jenkins** for continuous deployment within a secured Azure environment.

## Project Architecture
<img width="4680" height="7265" alt="ansible-lab-rg" src="https://github.com/user-attachments/assets/70a3f873-e806-4b1e-bd53-3eeca2e2a8ec" />

The architecture is built on a multi-tier design, ensuring high availability, security, and clear separation of concerns.

* **Load Balancing Layer:** An Nginx instance acting as a public-facing entry point. It handles HTTP traffic and serves as a Bastion Host (Jump Host) for internal SSH management.
* **Application Layer:** Multiple Nginx web servers residing in a private subnet, isolated from direct public internet access.
* **Database Layer:** Azure Database for PostgreSQL (Flexible Server) integrated into a delegated private subnet. It utilizes a Private DNS Zone for internal resolution, ensuring the database is completely unreachable from external networks.
* **Network Security:** Strict Network Security Group (NSG) rules allow only Port 22 (SSH) and Port 80 (HTTP) to the Load Balancer, while internal traffic is restricted to necessary service ports.

## Technical Implementation Details

### Remote State Management
To maintain idempotency and enable team-based development, the Terraform state is stored remotely in an **Azure Storage Account**. This configuration provides state locking and a single source of truth for the infrastructure, preventing conflicts during automated Jenkins runs.

### Jenkins & Python Virtual Environment (venv)
To ensure environment isolation and avoid dependency conflicts on the CI/CD worker, the pipeline executes within a dedicated **Python Virtual Environment**. This environment handles the installation of specific Ansible collections and Python libraries required for the deployment.

### Terraform-Rendered Inventory (Template Pattern)
The project utilizes a dynamic-to-static inventory approach. Terraform uses a `.tmpl` file to generate a `hosts.yml` inventory during the `apply` stage. This file captures:
* The Public IP of the Load Balancer.
* The Private IPs of the backend Web Servers.
* The Private FQDN of the PostgreSQL instance.

This ensures that Ansible always has the most recent network data without manual intervention.

### SSH ProxyJump and Security
Security is maintained by using the Load Balancer as a secure gateway. Ansible is configured to use **ProxyJump** logic, allowing it to provision private web servers by tunneling through the Load Balancer. Credentials and keys are managed via **Ansible Vault** and Jenkins **SSH Agent**, ensuring no secrets are stored in plain text or leaked into build logs.

## Deployment Workflow

<img width="1280" height="446" alt="image" src="https://github.com/user-attachments/assets/aa1b43de-ca1c-4780-9d55-86d1c8910fa7" />


1. **Infrastructure Provisioning:** Terraform initializes the backend, creates the Azure Resource Group, VNet, subnets, and virtual machines.
2. **Inventory Generation:** Terraform renders the `hosts.yml` file with live resource data.
3. **Database Configuration:** Ansible connects to the PostgreSQL instance via the Bastion Host to manage roles, users, and permissions.
4. **Web Tier Setup:** Ansible installs Nginx on backend servers and deploys the application content.
5. **Load Balancer Configuration:** The front-end Nginx is configured with an upstream block that dynamically includes all backend server IPs, ensuring proper traffic distribution.

## Evolution of Inventory Management Strategy

Initially, the project aimed to implement the `azure_rm` dynamic inventory plugin to query the Azure API in real-time. However, during development, it was determined that subscription-level constraints—specifically the inability to create a Service Principal (SP) with sufficient Entra ID permissions—made this approach unfeasible. Furthermore, the overhead of maintaining Azure CLI authentication within a headless CI/CD environment introduced unnecessary complexity.

The decision was made to pivot to a **Terraform-rendered inventory**. This strategy proved more robust for this environment, as it:
* Eliminated the dependency on external API calls during the Ansible phase.
* Reduced execution time by providing a ready-to-use host list.
* Ensured 100% reliability regardless of Azure CLI session states or Service Principal limitations.

## Verification and Proof of Work

### 1. Application Load Balancing
The success of the deployment can be verified by querying the Load Balancer's public IP. The Nginx upstream configuration ensures a Round-Robin distribution between the private web servers.
<img width="1064" height="151" alt="image" src="https://github.com/user-attachments/assets/41778c4b-d081-4f84-9e46-cba5de2b04e5" />
### 2. Database Provisioning & Authentication
Because the PostgreSQL Flexible Server is deployed within a private subnet without public access, verification must be performed from within the environment. Connecting via the Bastion Host (Load Balancer) confirms that Ansible successfully connected, decrypted the Vault secrets, and provisioned the required application users and roles
<img width="1269" height="521" alt="image" src="https://github.com/user-attachments/assets/f3614a48-b67a-4d83-9fdf-cb3c0890fe91" />
