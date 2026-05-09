# Wiz Tech Task – Cloud Security Demo Environment

## Overview

This project provisions a deliberately vulnerable cloud-native environment in AWS to demonstrate common security misconfigurations and how they can be identified and analyzed.

The infrastructure is deployed using **Terraform** and the application is deployed via **GitHub Actions CI/CD** into **Amazon EKS**.

---

## Architecture

```
Internet
   ↓
AWS Application Load Balancer (via Ingress)
   ↓
Kubernetes Ingress
   ↓
Service (ClusterIP)
   ↓
Tornado Web Application (Pod)
   ↓
MongoDB (EC2 Instance)
   ↓
S3 (Public Backups)
```

---

## Components

### Infrastructure (Terraform)
- VPC with public/private subnets
- EKS cluster (managed node group)
- EC2 instance running MongoDB
- S3 bucket for backups
- IAM roles and policies (intentionally over-permissive)
- AWS Load Balancer Controller (via Helm)

### Application
- Tornado web application (Docker)
- MongoDB backend

### CI/CD
- GitHub Actions pipeline:
  - Build image
  - Push to ECR
  - Deploy via Helm

---

## Security Misconfigurations (Intentional)

### 1. Overly Permissive IAM Role
- EC2 instance has broad permissions (`ec2:*`, `iam:*`, `s3:*`)
- Demonstrates privilege escalation risk

### 2. Public S3 Bucket
- Allows public read + list
- Demonstrates data exposure

### 3. Outdated OS / Software
- Old Linux AMI
- Outdated MongoDB

### 4. SSH Open to Internet
- `0.0.0.0/0` access on port 22

### 5. Kubernetes Admin Privileges
- App bound to `cluster-admin`

### 6. MongoDB Network + Auth Controls
- Only accessible from EKS nodes (security group)
- Requires username/password

---

## Deployment

### Terraform

```
terraform init
terraform apply
```

### CI/CD

Push to main branch:

```
git push origin main
```

---

## Access

```
kubectl get ingress -n wiz-task
```

Open the ALB DNS URL.

---

## Verification

```
kubectl get all -n wiz-task
```

---

## Teardown

```
terraform destroy
```

---

## Notes

This environment is intentionally insecure and should **not** be used in production.
