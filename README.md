Task Manager Lab

This project is a serverless task management application built using AWS services, Terraform, and GitHub Actions. It features a backend API for managing tasks and a web-based frontend, following Infrastructure-as-Code and DevOps best practices.

📌 Overview

- The application allows users to:
- Create, view, update, and delete tasks.
- Interact through a React-based UI hosted on AWS S3.
- Access the backend via a REST API powered by AWS Lambda and API Gateway.

🏗️ Technologies & Tools

- AWS Services: Lambda, API Gateway, DynamoDB, S3, IAM, KMS, CloudWatch, X-Ray.
- Terraform: Modular architecture for infrastructure provisioning.
- CI/CD: GitHub Actions automates deployment and destruction.

Testing:

- Backend: Automated with Go.
- Security: Scanned with Checkov and Terrascan.

🧪 Testing & Automation

- Full backend and security test coverage.
- GitHub Actions runs Go unit tests and security scans during deployment.
- Manual and automated workflows for apply and destroy.

🔧 Project Structure

- Modularized Terraform (/modules/backend, /modules/frontend)
- Lambda in Python for API logic.
- Static frontend in /frontend (HTML/CSS/JS).
- GitHub Actions workflows under .github/workflows/.

🔗 Links

- GitHub Repo: https://github.com/skan06/task-manager-lab
- Live UI (S3): task-manager-frontend-58d68d01.s3-website-us-east-1.amazonaws.com
- API Endpoint: Output from Terraform (dynamic)

Author: Skander Houidi

