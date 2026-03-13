# 🚀 Automated Azure CI/CD Pipeline & FastAPI Application

An end-to-end DevOps project demonstrating Infrastructure as Code (IaC), containerization, and continuous delivery. This project eliminates the "it works on my machine" problem by standardizing the environment and automating the entire deployment lifecycle from a local code commit to a live, cloud-hosted application.

## System Architecture

This pipeline is built on a modern DevOps toolchain:

1. **Source Control (GitHub):** Single source of truth for both application code and infrastructure configuration.
   
3. **Infrastructure as Code (Terraform):** Defines Azure networking, security groups, container registry, and virtual machines. Uses a declarative approach and state management so infrastructure is reproducible, version-controlled, and can be destroyed instantly.
   
5. **CI/CD Automation (GitHub Actions):** A YAML-based workflow that triggers on pushes to the main branch. Native GitHub integration removes the need for a separate CI server like Jenkins.
   
7. **Containerization (Docker):** Packages the FastAPI application and its dependencies into a single portable artifact, guaranteeing the same behavior in production as on a local machine.
   
9. **Image Storage (Azure Container Registry):** Private registry for Docker images within the Azure ecosystem, enabling low-latency and secure image pulls to the VM.
    
11. **Compute (Azure Virtual Machine):** Ubuntu Linux server hosting the running application with full control over the OS, networking, and Docker daemon.

## Key Engineering Decisions

* **Zero-Downtime Deployments:** The deployment script pulls the new image before stopping the old container, minimizing downtime during updates.
  
* **Security First:** Azure Network Security Groups restrict traffic to SSH (Port 22) and HTTP (Port 8000) only. Credentials and SSH keys are managed via GitHub Secrets and never hardcoded.
  
* **Automated Bootstrapping:** The deployment script checks for Docker and the Azure CLI on the VM and installs them automatically if missing.

## 🛠️ How to Run

### 1. Provision the Infrastructure

Make sure you have the Azure CLI and Terraform installed, then run:

```bash
az login
terraform init
terraform plan
terraform apply --auto-approve
```

### 2. Configure GitHub Secrets

After Terraform finishes, add these values to your repository under Settings > Secrets and variables > Actions:

* **AZURE_CREDENTIALS** — Service Principal JSON for Azure authentication.
  
* **ACR_LOGIN_SERVER** — URL of the container registry Terraform created.
  
* **VM_HOST_IP** — Public IP of the Virtual Machine.
  
* **VM_SSH_PRIVATE_KEY** — Your private SSH key for remote access.

### 3. Deploy the Application

Push any change to the `main` branch. The `.github/workflows/deploy.yml` pipeline will automatically log into Azure, build the Docker image, push it to the registry, SSH into the VM, and start the container on Port 8000.

The app will be live at `http://<VM_PUBLIC_IP>:8000/docs`.

### 4. Tear It All Down

When done, destroy all cloud resources to avoid unnecessary costs:

```bash
terraform destroy --auto-approve
```

---

