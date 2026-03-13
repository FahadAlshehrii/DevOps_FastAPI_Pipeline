https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white
https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white
https://img.shields.io/badge/Terraform-623CE4?style=for-the-badge&logo=terraform&logoColor=white
https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white
https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white
https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white

# 🚀 Automated Azure CI/CD Pipeline & FastAPI Application

An end-to-end DevOps project demonstrating Infrastructure as Code (IaC), containerization, and continuous delivery. This project eliminates the "it works on my machine" problem by standardizing the environment and automating the entire deployment lifecycle from a local code commit to a live, cloud-hosted application.

## System Architecture

This pipeline is built on a modern DevOps toolchain:

1. **Source Control (GitHub):** Single source of truth for both application code and infrastructure configuration.
2. **Infrastructure as Code (Terraform):** Defines Azure networking, security groups, container registry, and virtual machines. Uses a declarative approach so infrastructure is reproducible, version-controlled, and can be destroyed instantly.
3. **CI/CD Automation (GitHub Actions):** A YAML-based workflow that triggers on pushes to the main branch. Native GitHub integration removes the need for a separate CI server like Jenkins.
4. **Containerization (Docker):** Packages the FastAPI application and its dependencies into a single portable artifact, guaranteeing the same behavior in production as on a local machine.
5. **Image Storage (Azure Container Registry):** Private registry for Docker images within the Azure ecosystem, enabling low-latency and secure image pulls to the VM.
6. **Compute (Azure Virtual Machine):** Ubuntu Linux server hosting the running application with full control over the OS, networking, and Docker daemon.

## Code Highlights

Here are the core configuration snippets that power this project:

### 1. Infrastructure as Code (Terraform)

Terraform provisions all Azure resources. This snippet shows the creation of the private Azure Container Registry used to securely store Docker images:

```hcl
resource "azurerm_container_registry" "acr" {
  name                = "myprojectacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}
```

### 2. Containerization (Dockerfile)

The application is packaged using a slim Python image to keep image size minimal:

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 3. Continuous Deployment (GitHub Actions)

After the image is built, the pipeline SSHs into the Azure VM, authenticates using injected secrets, and deploys the new container with no manual intervention needed:

```yaml
      - name: Deploy to VM via SSH
        uses: appleboy/ssh-action@v1.0.3
        env:
          APP_ID: ${{ fromJSON(secrets.AZURE_CREDENTIALS).clientId }}
          PASSWORD: ${{ fromJSON(secrets.AZURE_CREDENTIALS).clientSecret }}
          TENANT: ${{ fromJSON(secrets.AZURE_CREDENTIALS).tenantId }}
        with:
          host: ${{ secrets.VM_HOST_IP }}
          username: adminuser
          key: ${{ secrets.VM_SSH_PRIVATE_KEY }}
          envs: APP_ID,PASSWORD,TENANT
          script: |
            sudo az login --service-principal -u $APP_ID -p $PASSWORD --tenant $TENANT
            sudo az acr login --name ${{ secrets.ACR_LOGIN_SERVER }}
            sudo docker stop fastapi-app || true
            sudo docker rm fastapi-app || true
            sudo docker pull ${{ secrets.ACR_LOGIN_SERVER }}/my-fastapi-app:latest
            sudo docker run -d --name fastapi-app -p 8000:8000 ${{ secrets.ACR_LOGIN_SERVER }}/my-fastapi-app:latest
```

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

After Terraform finishes, add these values to your repository under **Settings > Secrets and variables > Actions**. The GitHub Actions workflow relies on these secrets to automatically and securely authenticate during the deployment process :

* **AZURE_CREDENTIALS:** Service Principal JSON for Azure authentication.
* **ACR_LOGIN_SERVER:** URL of the private container registry Terraform created.
* **VM_HOST_IP:** Public IP address of the Virtual Machine.
* **VM_SSH_PRIVATE_KEY:** Your local private SSH key for remote access to the server.

### 3. Deploy the Application

Push any change to the `main` branch. The `.github/workflows/deploy.yml` pipeline will automatically log into Azure, build the Docker image, push it to the registry, SSH into the VM, and start the container on Port 8000.

The app will be live at `http://<VM_PUBLIC_IP>:8000/docs`.

### 4. Tear It All Down

When done, destroy all cloud resources to avoid unnecessary costs:

```bash
terraform destroy --auto-approve
```

## Future Plans

* **Kubernetes (AKS):** Migrate from a single VM to Azure Kubernetes Service for automatic scaling, self-healing pods, and rolling deployments with zero downtime.
* **Multi-Region Deployment:** Expand the infrastructure across multiple Azure regions with load balancing to improve availability and reduce latency for users globally.
* **Monitoring with Grafana & Prometheus:** Integrate Prometheus to scrape application and container metrics, and visualize them through Grafana dashboards for real-time observability into performance, uptime, and resource usage.
