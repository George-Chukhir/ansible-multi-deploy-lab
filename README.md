<img width="828" height="230" alt="image" src="https://github.com/user-attachments/assets/ee268c04-db48-473d-a318-0aac47d53572" />
# Multi-Tier Web Infrastructure: Ansible & Docker Lab

This repository contains an automated Infrastructure-as-Code (IaC) project for deploying a load-balanced web application environment. It uses **Ansible** for configuration management and **Jenkins** for continuous deployment.

## Project Architecture

The project deploys a complete multi-tier stack within a local Docker network:

* **Load Balancer (`lb-01`):** Nginx configured as a reverse proxy using the Round Robin algorithm.
* **Web Servers (`app-01`, `app-02`):** Nginx backend servers serving dynamic HTML content.
* **Database (`db-01`):** PostgreSQL server (initial setup).

## Key Technologies
* **Ansible:** Configuration management using Roles and Jinja2 templates.
* **Docker & Docker Compose:** Container orchestration for the local environment.
* **Jenkins:** Automated CI/CD pipeline execution.
* **Ansible Vault:** Secure management of sensitive data (passwords, keys).

## Repository Structure

Following Enterprise best practices, the project is structured as follows:

```text
.
├── Jenkinsfile                 # CI/CD pipeline definition
├── deploy_local/               # Target infrastructure orchestration
│   └── docker-compose.yml      # Defines LB, App, and DB containers
└── ansible/                    # Configuration management logic
    ├── ansible.cfg             # Ansible configuration (stdout, safe.directory)
    ├── master_playbook.yml     # Root playbook
    ├── roles/                  # Reusable logic per service
    │   ├── nginx_backend/      # Configures App servers
    │   └── nginx_loadbalancer/ # Configures the Load Balancer
    └── inventories/
        └── local_docker/       # Inventory and group variables
            ├── hosts.yml
            └── group_vars/all.yml
