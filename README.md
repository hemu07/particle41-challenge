# SimpleTimeService

SimpleTimeService is a lightweight Python microservice that returns the current timestamp and the client IP address in JSON format.

The project demonstrates:
- A simple web service (Python + Flask)
- Containerization with Docker (multi-stage, distroless, non-root)
- Infrastructure as Code using Terraform
- Deployment to AWS ECS (Fargate) behind an Application Load Balancer

This repository is intended as a reference implementation for cloud-native application deployment and infrastructure automation.

---

## 🧩 Application Overview

### API Endpoint

**GET /**

Example response:
```json
{
  "timestamp": "2025-01-01T12:34:56Z",
  "ip": "203.0.113.10"
}
```
---------------------------------------------------------------------------------------------------------------------------------

📁 Repository Structure
```
simple-time-service/
├── app.py                     # Python application
├── Dockerfile                 # Multi-stage, distroless Docker image
└── terraform/
    ├── main.tf                # AWS infrastructure (VPC, ECS, ALB)
    ├── variables.tf           # Terraform variables
    ├── output.tf              # Terraform outputs
    ├── terraform.tfvars.example
    └── .gitignore
```
🔧 Prerequisites

The following tools are required to deploy this project.
1️⃣ Operating System
Amazon Linux 2023 
2️⃣ Install Git : https://git-scm.com/
```
sudo yum install git -y
```
3️⃣ Install Docker : https://docs.docker.com/get-started/get-docker/
```
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
```
verify if docker is installed correctly:
```
docker version
```
4️⃣ Install AWS CLI v2 (Amazon linux 2023 comes preinstalled with aws cli, so skipping this step)
you can verify aws cli by -
```
aws --version
```
Link to install aws CLI if on other OS -
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html

5️⃣ Install Terraform - https://developer.hashicorp.com/terraform/downloads
```
sudo yum install -y dnf-plugins-core
sudo yum config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install terraform -y
```
verify terraform installation by -  
```
terraform version
```

🔐 AWS Credentials Configuration
Configure an IAM role with below permissions so that EC2 can launch and create resources on your behalf ( this is better option as compared to AWS configure option as anyone who has access to this machine can get your 
crednetials and misuse it, so its better to use IAM role attach it to instance from "modify IAM role" option available in ec2 console

Attach below permission to IAM role-

AmazonEC2ContainerRegistryFullAccess
AmazonEC2FullAccess
AmazonECS_FullAccess
AmazonVPCFullAccess
ElasticLoadBalancingFullAccess
IAMFullAccess

🐳 Build Docker Image and Run Locally
```
docker build -t simple-time-service .
```
Run the container
```
docker run -p 5000:5000 simple-time-service
```
Test in browser
http://public-ip-of-instance:5000

you should get below output -
```
{
  "timestamp": "2025-12-19T15:39:15.408020Z",
  "ip": "103.228.147.80"
}
```
<img width="1919" height="249" alt="image" src="https://github.com/user-attachments/assets/afd0d273-ce3e-465f-8b4b-dee87dabe39d" />

📦 Push Image to Amazon ECR
Create ECR Repository
```
aws ecr create-repository \
  --repository-name simple-time-service \
  --region us-east-1
```
Authenticate Docker to ECR
```
aws ecr get-login-password --region us-east-1 \
| docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```
Build, Tag, and Push image to ECR
```
docker build -t simple-time-service .
docker tag simple-time-service:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/simple-time-service:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/simple-time-service:latest
```

🏗️ Deploy Infrastructure with Terraform
1️⃣ Configure Terraform Variables
Edit terraform.tfvars with image URI just created in previous step
```
image = "<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/simple-time-service:latest"
```

2️⃣ Initialize Terraform
```
cd terraform
terraform init
```

3️⃣ Apply Terraform
```
terraform apply
```
it will prompt for "yes" (24 resources will be created)

4️⃣ Access the Application
After deployment, Terraform outputs the ALB DNS name:
```
terraform output
```
Open the URL in a browser:
http://alb-dns-name


----------------------------------------------------------------------------------------------------
🧠 Design Considerations-->

ECS Fargate used to avoid managing servers
Private subnets for application tasks
Public ALB for internet access
Distroless Docker image for security and size optimization
Infrastructure fully reproducible via Terraform

🧹 Cleanup
To destroy all AWS resources:
```
terraform destroy
```

📌 Notes:
Terraform state is stored locally in this setup for simplicity.
In a production environment, a remote backend (S3 + DynamoDB) is recommended.
This project is intended for demonstration and learning purposes.
IAM policies and security groups can be further restricted if required.

