[README.md](https://github.com/user-attachments/files/25964578/README.md)
# Automated Azure CI/CD Pipeline and FastAPI Application

An end-to-end DevOps project demonstrating Infrastructure as Code (IaC), containerization, and continuous delivery. 

The primary goal of this project is to eliminate the "it works on my machine" problem by standardizing the application environment and automating the entire deployment lifecycle—from a local code commit to a live, cloud-hosted application accessible on the public internet.

## System Architecture and The "Whys"

This pipeline is built on a modern DevOps toolchain. Here is how the system flows and why each tool was selected:

1. Source Control (GitHub): Acts as the single source of truth for both application code and infrastructure configuration. 
2. Infrastructure as Code (Terraform): Defines the Azure networking, security groups, container registry, and virtual machines. 
   * Why Terraform? It uses a declarative approach and state management, meaning the infrastructure is highly reproducible, version-controlled, and can be destroyed instantly to manage cloud costs.
3. CI/CD Automation (GitHub Actions): A YAML-based workflow that listens for code pushes to the main branch. 
   * Why GitHub Actions? It provides native integration with the repository, eliminating the overhead of managing and hosting a separate continuous integration server like Jenkins.
4. Containerization (Docker): Packages the FastAPI application and its dependencies into a single, portable artifact.
   * Why Docker? It guarantees that the application runs exactly the same in the production cloud environment as it does on a developer's local laptop.
5. Image Storage (Azure Container Registry): A secure, private vault for storing built Docker images.
   * Why ACR? Keeping the registry within the Azure ecosystem ensures low-latency, highly secure image pulls to the Azure Virtual Machine without traversing the public internet.
6. Compute (Azure Virtual Machine): An Ubuntu Linux server that hosts the running application. 
   * Why a VM? It provides absolute control over the host operating system, networking rules, and Docker daemon configurations.

## Key Engineering Decisions

* Zero-Downtime Mentality: The deployment script on the Virtual Machine is designed to pull the new image before tearing down the old container, minimizing application downtime during updates.
* Security First: Infrastructure is locked down via Azure Network Security Groups. Only SSH (Port 22) and HTTP (Port 8000) traffic are permitted. Furthermore, Azure credentials and SSH keys are never hardcoded; they are strictly managed via GitHub Secrets and passed into the runner environment dynamically.
* Automated Environment Bootstrapping: The SSH deployment script includes conditional logic to check for the presence of Docker and the Azure CLI. If the Virtual Machine is newly provisioned and blank, the script automatically installs the required dependencies before attempting to deploy the application.

## How to Run (Local to Cloud)

If you want to spin this project up yourself, I have designed it to be completely automated. Here is exactly what you should do to get it running on your own Azure account.

### 1. Provision the Infrastructure
First, you need to make sure you have the Azure CLI and Terraform installed on your local machine. I wrote the Terraform configuration so that it handles all the heavy lifting. Open your terminal in the project folder and run these commands to log into Azure and build the physical cloud resources:

```bash
az login
terraform init
terraform plan
terraform apply --auto-approve
```

### 2. Configure Your GitHub Secrets

Once Terraform finishes, it will print out several specific values in your terminal. You need to copy these and add them to your GitHub repository's Secrets (Settings > Secrets and variables > Actions). I set up the pipeline to strictly use these secrets so no passwords are ever hardcoded. You should add:

* **AZURE_CREDENTIALS:** The Service Principal JSON block you generated for Azure. This tells the pipeline exactly who you are.
* **ACR_LOGIN_SERVER:** The URL of the private container registry Terraform just built for you.
* **VM_HOST_IP:** The public IP address of your brand-new Ubuntu Virtual Machine.
* **VM_SSH_PRIVATE_KEY:** The raw text of your local private SSH key. The pipeline uses this to securely remote into the server.

### 3. Deploy the Application

Now for the actual deployment. All you have to do is make a code change and push it to the `main` branch.

The moment you push, my `.github/workflows/deploy.yml` pipeline will take over. You can navigate to the "Actions" tab in GitHub and watch as it automatically logs into Azure, builds the FastAPI Docker image, pushes it to the private registry, SSHs into the Virtual Machine, and starts the container on Port 8000.

Once the deployment succeeds, the FastAPI application is no longer running on localhost; it is live on the public internet and can be accessed via any web browser at `http://<VM_PUBLIC_IP>:8000/docs`.

### 4. Tear It All Down

I am highly focused on cloud cost optimization. When you are finished reviewing the live application, you should tear down the environment so you do not leave expensive servers running in the background. Simply run this command in your local terminal, and Terraform will safely destroy everything it created:

```bash
terraform destroy --auto-approve
```
