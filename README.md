# 🚀 Automated Azure CI/CD Pipeline & FastAPI Application

![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-623CE4?style=for-the-badge&logo=terraform&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)

An end-to-end DevOps project demonstrating Infrastructure as Code (IaC), containerization, and continuous delivery.

This project eliminates the "it works on my machine" problem by standardizing the environment and automating the entire deployment lifecycle from a local code commit to a live, cloud-hosted application accessible on the public internet.

## System Architecture and The "Whys"

This pipeline is built on a modern DevOps toolchain. Here is how the system flows and why each tool was selected:

1. **Source Control (GitHub):** Acts as the single source of truth for both application code and infrastructure configuration.
2. **Infrastructure as Code (Terraform):** Defines the Azure networking, security groups, container registry, and virtual machines.
   * Why Terraform? It uses a declarative approach and state management, meaning the infrastructure is highly reproducible, version-controlled, and can be destroyed instantly to manage cloud costs.
3. **CI/CD Automation (GitHub Actions):** A YAML-based workflow that triggers on pushes to the main branch.
   * Why GitHub Actions? Native GitHub integration removes the need for managing and hosting a separate continuous integration server like Jenkins.
4. **Containerization (Docker):** Packages the FastAPI application and its dependencies into a single, portable artifact.
   * Why Docker? It guarantees that the application runs exactly the same in the production cloud environment as it does on a developer's local laptop.
5. **Image Storage (Azure Container Registry):** A secure, private vault for storing built Docker images.
   * Why ACR? Keeping the registry within the Azure ecosystem ensures low-latency, highly secure image pulls to the Azure Virtual Machine without traversing the public internet.
6. **Compute (Azure Virtual Machine):** An Ubuntu Linux server that hosts the running application.
   * Why a VM? It provides absolute control over the host operating system, networking rules, and Docker daemon configurations.

## Code Highlights

Here are the core configuration snippets that power the pipeline:

### 1. Infrastructure as Code (Terraform)

Terraform provisions all Azure resources. This snippet shows the creation of the private Azure Container Registry used to securely store the Docker images:

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

The application is packaged using a slim Python image to keep the image size as small as possible:

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

After the image is built, the pipeline securely SSHs into the Azure VM, authenticates using injected secrets, and deploys the new container with no manual intervention needed. Notice the conditional logic that automatically installs Docker and Azure CLI if the server is blank:

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
            if ! command -v docker &> /dev/null; then
              curl -fsSL https://get.docker.com -o get-docker.sh
              sudo sh get-docker.sh
            fi
            if ! command -v az &> /dev/null; then
              curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
            fi

            sudo az login --service-principal -u $APP_ID -p $PASSWORD --tenant $TENANT
            sudo az acr login --name ${{ secrets.ACR_LOGIN_SERVER }}
            sudo docker stop fastapi-app || true
            sudo docker rm fastapi-app || true
            sudo docker pull ${{ secrets.ACR_LOGIN_SERVER }}/my-fastapi-app:latest
            sudo docker run -d --name fastapi-app -p 8000:8000 ${{ secrets.ACR_LOGIN_SERVER }}/my-fastapi-app:latest
```

## Key Engineering Decisions

* **Zero-Downtime Deployments:** The deployment script pulls the new image before tearing down the old container, minimizing application downtime during updates.
* **Security First:** Infrastructure is locked down via Azure Network Security Groups. Only SSH (Port 22) and HTTP (Port 8000) traffic are permitted. Azure credentials and SSH keys are never hardcoded; they are strictly managed via GitHub Secrets.
* **Automated Bootstrapping:** The SSH deployment script includes conditional logic to check for the presence of Docker and the Azure CLI, installing them automatically if they are missing.

## 🛠️ How to Run

### 1. Provision the Infrastructure

Make sure you have the Azure CLI and Terraform installed on your local machine, then run:

```bash
az login
terraform init
terraform plan
terraform apply --auto-approve
```

### 2. Configure GitHub Secrets

After Terraform finishes, add these values to your repository under **Settings > Secrets and variables > Actions**. The GitHub Actions workflow relies on these secrets to automatically and securely authenticate during the deployment process:

* **AZURE_CREDENTIALS:** Service Principal JSON for Azure authentication.
* **ACR_LOGIN_SERVER:** URL of the private container registry Terraform created.
* **VM_HOST_IP:** Public IP address of the Virtual Machine.
* **VM_SSH_PRIVATE_KEY:** Your local private SSH key for remote access to the server.

### 3. Deploy the Application

Push any code changes to the `main` branch. The `.github/workflows/deploy.yml` pipeline will automatically log into Azure, build the Docker image, push it to the registry, SSH into the VM, and start the container on Port 8000.

The app will be live at `http://<VM_PUBLIC_IP>:8000/docs`.

### 4. Tear It All Down

When done, destroy all cloud resources to avoid unnecessary Azure costs:

```bash
terraform destroy --auto-approve
```

## Future Plans

* **Kubernetes (AKS):** Migrate from a single VM to Azure Kubernetes Service for automatic scaling, self-healing pods, and rolling deployments with zero downtime.
* **Multi-Region Deployment:** Expand the infrastructure across multiple Azure regions with load balancing to improve availability and reduce latency for users globally.
* **Monitoring with Grafana & Prometheus:** Integrate Prometheus to scrape application and container metrics, and visualize them through Grafana dashboards for real-time observability into performance, uptime, and resource usage.
