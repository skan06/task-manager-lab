🗂️ Task Manager Lab

This project is a serverless full-stack CRUD application for task management, built using AWS, Terraform, and GitHub Actions. It follows Infrastructure-as-Code (IaC) and DevOps best practices to ensure automation, scalability, and maintainability.

📌 Overview
The Task Manager app enables users to:

🔹 Create, read, update, and delete (CRUD) tasks.
🔹 Interact through a React-based UI hosted on Amazon S3.
🔹 Access the backend via a RESTful API built with AWS Lambda and API Gateway.
🔹 Persist data using Amazon DynamoDB.

🏗️ Technologies & Tools
AWS Services
🔹 Lambda (Python) – backend logic
🔹 API Gateway – REST endpoints
🔹 DynamoDB – task storage
🔹 S3 – static frontend hosting
🔹 IAM, KMS – access control and encryption
🔹 CloudWatch & X-Ray – monitoring & tracing

Infrastructure & Automation
🔹 Terraform – modular provisioning of AWS infrastructure
🔹 GitHub Actions – CI/CD for deployment and teardown

Testing & Security
🔹 Go – unit testing with Terratest
🔹 Checkov & Terrascan – IaC security scanning

🧪 Testing & Automation
🔹 Automated Go tests cover backend behavior.
🔹 GitHub Actions pipeline runs tests and security scans on every push.
🔹 Manual and automatic workflows for Terraform apply and destroy.

🔧 Project Structure
task-manager-lab/
├── frontend/                  # React UI (HTML/CSS/JS)
├── lambda/                   # Python Lambda backend
├── modules/
│   ├── backend/              # Terraform module: Lambda, API, DynamoDB
│   └── frontend/             # Terraform module: S3 hosting
├── tests/                    # Terratest Go tests
├── .github/workflows/        # CI/CD with GitHub Actions
├── main.tf, variables.tf     # Root Terraform configs

🔗 Links
🌐 GitHub Repository:
https://github.com/skan06/task-manager-lab

🌐 Live Frontend (S3):
task-manager-frontend-58d68d01.s3-website-us-east-1.amazonaws.com

🌐 API Endpoint:
Provisioned dynamically via Terraform output

👨‍💻 Author: Skander Houidi