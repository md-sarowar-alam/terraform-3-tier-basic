# BMI Health Tracker - Terraform Infrastructure

This directory contains the Terraform configuration to deploy the BMI Health Tracker application on AWS EC2.

## 📋 Overview

This Terraform configuration deploys a complete 3-tier application (Frontend, Backend, Database) on a single EC2 instance:

- **Frontend**: React app served by Nginx
- **Backend**: Node.js/Express API
- **Database**: PostgreSQL

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         AWS EC2 Instance                │
│  ┌───────────────────────────────────┐  │
│  │   Nginx (Port 80)                 │  │
│  │   ├── Frontend (React)            │  │
│  │   └── Reverse Proxy → Backend     │  │
│  ├───────────────────────────────────┤  │
│  │   Backend (Node.js - Port 3000)   │  │
│  │   └── Systemd Service             │  │
│  ├───────────────────────────────────┤  │
│  │   PostgreSQL Database             │  │
│  │   ├── Database: bmidb             │  │
│  │   └── User: bmi_user              │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## 📁 Project Structure

```
terraform/
├── backend.tf                 # S3 backend configuration
├── main.tf                    # Root module
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example variables file
├── .gitignore                 # Git ignore rules
├── README.md                  # This file
└── modules/
    └── ec2/
        ├── main.tf            # EC2 instance resource
        ├── variables.tf       # Module variables
        └── outputs.tf         # Module outputs
```

## 🚀 Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured with a named profile
3. **Terraform** >= 1.0 installed
4. **S3 Bucket** for Terraform state (create manually)
5. **EC2 Key Pair** created in your AWS region
6. **VPC, Subnet, and Security Group** IDs

### Required Security Group Rules

Your security group must allow:

| Type  | Protocol | Port Range | Source      | Description                    |
|-------|----------|------------|-------------|--------------------------------|
| SSH   | TCP      | 22         | Your IP     | SSH access                     |
| HTTP  | TCP      | 80         | 0.0.0.0/0   | Web application access         |
| HTTPS | TCP      | 443        | 0.0.0.0/0   | HTTPS (optional, for future)   |

## 📝 Setup Instructions

### Step 1: Create S3 Bucket for State

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://my-terraform-state-bucket --region us-east-1 --profile default

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled \
  --profile default

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket my-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --profile default
```

### Step 2: Update Backend Configuration

Edit [backend.tf](backend.tf) and update:

```hcl
terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket"  # Your bucket name
    key     = "bmi-app/terraform.tfstate"
    region  = "us-east-1"                  # Your region
    profile = "default"                     # Your AWS profile
    encrypt = true
  }
}
```

### Step 3: Create terraform.tfvars

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
notepad terraform.tfvars  # Windows
# or
nano terraform.tfvars     # Linux/Mac
```

Update the following required variables:
- `aws_profile`: Your AWS CLI profile name
- `key_name`: Your EC2 key pair name
- `vpc_id`: Your VPC ID
- `subnet_id`: Your public subnet ID
- `security_group_id`: Your security group ID
- `db_password`: A strong database password
- `ami_id`: Ubuntu 22.04 AMI for your region

### Step 4: Find Ubuntu AMI for Your Region

```bash
# Find latest Ubuntu 22.04 LTS AMI
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'sort_by(Images, &CreationDate)[-1].[ImageId,Name]' \
  --output text \
  --region us-east-1 \
  --profile default
```

### Step 5: Initialize Terraform

```bash
cd terraform
terraform init
```

### Step 6: Plan the Deployment

```bash
terraform plan
```

Review the planned changes carefully.

### Step 7: Deploy

```bash
terraform apply
```

Type `yes` when prompted.

## 📊 Outputs

After successful deployment, Terraform will output:

- `instance_id`: EC2 instance ID
- `instance_public_ip`: Public IP address
- `application_url`: URL to access the application
- `ssh_connection_command`: SSH command
- `deployment_notes`: Detailed deployment information

Example:

```
Outputs:

application_url = "http://54.123.45.67"
instance_id = "i-0123456789abcdef0"
instance_public_ip = "54.123.45.67"
ssh_connection_command = "ssh -i <your-key.pem> ubuntu@54.123.45.67"
```

## 🔍 Monitoring Deployment

The deployment script runs automatically via userdata. Monitor the progress:

```bash
# SSH into the instance
ssh -i your-key.pem ubuntu@<public-ip>

# Check cloud-init status
cloud-init status

# View deployment logs
sudo tail -f /var/log/cloud-init-output.log
sudo tail -f /var/log/user-data.log
sudo tail -f /var/log/bmi-deployment.log

# Check backend service
sudo systemctl status bmi-backend

# View backend logs
sudo tail -f /var/log/bmi-backend.log

# Check Nginx
sudo systemctl status nginx
```

## ⚙️ Post-Deployment

### Access the Application

1. Wait 5-10 minutes for the deployment to complete
2. Open your browser and navigate to: `http://<public-ip>`
3. The BMI Health Tracker application should be running

### Useful Commands

```bash
# Check backend service
sudo systemctl status bmi-backend
sudo systemctl restart bmi-backend

# View logs
sudo tail -f /var/log/bmi-backend.log
sudo tail -f /var/log/nginx/bmi-access.log
sudo tail -f /var/log/nginx/bmi-error.log

# Connect to database
psql -U bmi_user -d bmidb -h localhost

# Nginx operations
sudo nginx -t                    # Test configuration
sudo systemctl restart nginx     # Restart Nginx
```

## 🔄 Updates and Changes

### Update the Application

To update the application code:

```bash
# SSH into the instance
ssh -i your-key.pem ubuntu@<public-ip>

# Navigate to app directory
cd /home/ubuntu/bmi-health-tracker

# Pull latest changes (if using git)
git pull

# Restart services
sudo systemctl restart bmi-backend
sudo systemctl restart nginx
```

### Modify Terraform Configuration

```bash
# Make changes to .tf files
# Plan changes
terraform plan

# Apply changes
terraform apply
```

## 🗑️ Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

**Warning**: This will delete the EC2 instance and all data on it. Make sure to backup any important data first!

## 🔒 Security Considerations

1. **State File Security**: The Terraform state file contains sensitive information (like database passwords). Always use S3 backend with encryption.

2. **Database Password**: Consider using AWS Secrets Manager or SSM Parameter Store for production.

3. **SSH Access**: Restrict SSH access to your IP address only.

4. **HTTPS**: Set up SSL/TLS using Let's Encrypt:
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d yourdomain.com
   ```

5. **Firewall**: Use AWS Security Groups to restrict access.

6. **Backups**: Set up regular database backups.

## 📚 Variables Reference

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region | us-east-1 | No |
| `aws_profile` | AWS CLI profile | default | No |
| `instance_name` | EC2 instance name | bmi-health-tracker-server | No |
| `instance_type` | EC2 instance type | t2.micro | No |
| `ami_id` | Ubuntu 22.04 AMI ID | ami-0e86e20dae9224db8 | No |
| `key_name` | EC2 key pair name | - | **Yes** |
| `vpc_id` | VPC ID | - | **Yes** |
| `subnet_id` | Public subnet ID | - | **Yes** |
| `security_group_id` | Security group ID | - | **Yes** |
| `db_name` | Database name | bmidb | No |
| `db_user` | Database user | bmi_user | No |
| `db_password` | Database password | - | **Yes** |

## 🐛 Troubleshooting

### Instance not accessible
- Check security group rules
- Verify subnet has internet gateway
- Confirm public IP is assigned

### Application not loading
- Check deployment logs: `sudo tail -f /var/log/cloud-init-output.log`
- Verify backend service: `sudo systemctl status bmi-backend`
- Check Nginx: `sudo systemctl status nginx`

### Database connection errors
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Check database credentials
- View backend logs: `sudo tail -f /var/log/bmi-backend.log`

## 📞 Support

For issues or questions:
1. Check the deployment logs
2. Review the application README
3. Verify all prerequisites are met
4. Ensure security groups and network configuration are correct

---

## 🧑‍💻 Author
**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: [linkedin.com/in/sarowar](https://www.linkedin.com/in/sarowar/)

---

**Note**: This configuration deploys a single-instance setup suitable for development and testing. For production, consider:
- Using RDS for PostgreSQL
- Setting up Auto Scaling
- Implementing Load Balancer
- Adding CloudWatch monitoring
- Implementing backup solutions
- Using separate environments (dev/staging/prod)
