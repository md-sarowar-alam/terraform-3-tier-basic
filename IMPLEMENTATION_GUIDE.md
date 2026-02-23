# BMI Health Tracker - Complete Implementation Guide

This guide walks you through deploying the BMI Health Tracker application on AWS using Terraform.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Understanding](#project-understanding)
3. [AWS Setup](#aws-setup)
4. [Terraform Configuration](#terraform-configuration)
5. [Deployment Steps](#deployment-steps)
6. [Verification](#verification)
7. [Post-Deployment](#post-deployment)
8. [Troubleshooting](#troubleshooting)

---

## 1. Prerequisites

### 1.1 Required Software

Install the following on your local machine:

```bash
# Check if installed
aws --version          # AWS CLI
terraform --version    # Terraform >= 1.0
git --version          # Git

# Installation guides
# AWS CLI: https://aws.amazon.com/cli/
# Terraform: https://www.terraform.io/downloads
# Git: https://git-scm.com/downloads
```

### 1.2 AWS Account Requirements

- Active AWS account
- IAM user with permissions for:
  - EC2 (create, manage instances)
  - VPC (if creating resources)
  - S3 (for state bucket)
- Credit card on file (free tier eligible)

### 1.3 Knowledge Prerequisites

Basic understanding of:
- AWS EC2, VPC, Security Groups
- Linux command line
- Git and version control
- Terraform basics

---

## 2. Project Understanding

### 2.1 What Gets Deployed

```
AWS Cloud
    ↓
Single EC2 Instance (Ubuntu 22.04)
    ├── Nginx (Port 80) → Frontend + Reverse Proxy
    ├── Node.js Backend (Port 3000) → API
    └── PostgreSQL (Port 5432) → Database
```

### 2.2 Deployment Process

1. **Terraform** creates EC2 instance
2. **Userdata** (user-data.sh) runs on boot:
   - Updates system packages
   - Installs Git
   - Clones application from GitHub
   - Sets database credentials
3. **IMPLEMENTATION_AUTO.sh** executes:
   - Installs Node.js, PostgreSQL, Nginx, PM2
   - Sets up database and runs migrations
   - Deploys backend as systemd service
   - Builds and deploys frontend
   - Configures Nginx

### 2.3 Time Estimate

- **Setup**: 15-20 minutes
- **Deployment**: 5-10 minutes (automated)
- **Total**: ~30 minutes

---

## 3. AWS Setup

### 3.1 Configure AWS CLI

```bash
# Configure AWS credentials
aws configure --profile default

# You'll be prompted for:
AWS Access Key ID: [Enter your key]
AWS Secret Access Key: [Enter your secret]
Default region name: us-east-1
Default output format: json

# Verify configuration
aws sts get-caller-identity --profile default
```

### 3.2 Create EC2 Key Pair

```bash
# Create new key pair
aws ec2 create-key-pair \
  --key-name bmi-health-tracker-key \
  --query 'KeyMaterial' \
  --output text \
  --profile default \
  > bmi-health-tracker-key.pem

# Set permissions
chmod 400 bmi-health-tracker-key.pem

# Save this file securely!
```

### 3.3 Identify Network Resources

#### Option A: Use Existing VPC

```bash
# List your VPCs
aws ec2 describe-vpcs \
  --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table \
  --profile default

# List subnets in your VPC (replace vpc-xxxxx)
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-xxxxx" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch,Tags[?Key==`Name`].Value|[0]]' \
  --output table \
  --profile default

# Note: Choose a subnet where MapPublicIpOnLaunch = True (public subnet)
```

#### Option B: Use Default VPC

```bash
# Get default VPC
aws ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text \
  --profile default

# Get a public subnet from default VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=<your-default-vpc-id>" \
  --query 'Subnets[0].SubnetId' \
  --output text \
  --profile default
```

### 3.4 Create Security Group

```bash
# Create security group
aws ec2 create-security-group \
  --group-name bmi-health-tracker-sg \
  --description "Security group for BMI Health Tracker" \
  --vpc-id vpc-xxxxx \
  --profile default

# Note the SecurityGroupId returned

# Add SSH rule (replace YOUR_IP with your public IP)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32 \
  --profile default

# Add HTTP rule
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0 \
  --profile default

# Add HTTPS rule (optional)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0 \
  --profile default

# Get your public IP
curl -4 ifconfig.me
```

### 3.5 Create S3 Bucket for Terraform State

```bash
# Create bucket (must be globally unique)
aws s3 mb s3://bmi-health-tracker-terraform-state-YOUR_INITIALS \
  --region us-east-1 \
  --profile default

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket bmi-health-tracker-terraform-state-YOUR_INITIALS \
  --versioning-configuration Status=Enabled \
  --profile default

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket bmi-health-tracker-terraform-state-YOUR_INITIALS \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --profile default

# Verify bucket created
aws s3 ls --profile default
```

---

## 4. Terraform Configuration

### 4.1 Clone Repository

```bash
# Clone the project
git clone https://github.com/md-sarowar-alam/terraform-3-tier-basic.git
cd terraform-3-tier-basic

# Review project structure
ls -la
```

### 4.2 Navigate to Terraform Directory

```bash
cd terraform
ls -la

# You should see:
# - main.tf
# - variables.tf
# - outputs.tf
# - backend.tf
# - terraform.tfvars.example
# - modules/
```

### 4.3 Configure Backend (backend.tf)

```bash
# Edit backend.tf
notepad backend.tf  # Windows
# or
nano backend.tf     # Linux/Mac

# Update the following:
terraform {
  backend "s3" {
    bucket  = "bmi-health-tracker-terraform-state-YOUR_INITIALS"  # Your bucket
    key     = "bmi-app/terraform.tfstate"
    region  = "us-east-1"                                         # Your region
    profile = "default"                                            # Your profile
    encrypt = true
  }
}
```

### 4.4 Create terraform.tfvars

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
notepad terraform.tfvars  # Windows
# or
nano terraform.tfvars     # Linux/Mac
```

### 4.5 Fill in Your Values

```hcl
# ===========================
# AWS Configuration
# ===========================
aws_region  = "us-east-1"              # Your AWS region
aws_profile = "default"                 # Your AWS CLI profile
environment = "dev"

# ===========================
# EC2 Instance Configuration
# ===========================
instance_name = "bmi-health-tracker-server"
instance_type = "t2.micro"              # Free tier eligible
ami_id        = "ami-0e86e20dae9224db8"  # Ubuntu 22.04 (us-east-1)
key_name      = "bmi-health-tracker-key" # Your key pair name

# ===========================
# Network Configuration
# ===========================
vpc_id            = "vpc-xxxxx"         # YOUR VPC ID
subnet_id         = "subnet-xxxxx"      # YOUR PUBLIC SUBNET ID
security_group_id = "sg-xxxxx"          # YOUR SECURITY GROUP ID

# ===========================
# Database Configuration
# ===========================
db_name     = "bmidb"
db_user     = "bmi_user"
db_password = "MySecurePassword123!"    # CHANGE THIS!

# ===========================
# Additional Tags
# ===========================
additional_tags = {
  Owner      = "Your Name"
  CostCenter = "Engineering"
}
```

### 4.6 Find Ubuntu AMI for Your Region

If you're not using us-east-1:

```bash
# Find latest Ubuntu 22.04 AMI for your region
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'sort_by(Images, &CreationDate)[-1].[ImageId,Name]' \
  --output text \
  --region YOUR_REGION \
  --profile default

# Use the ImageId in terraform.tfvars
```

---

## 5. Deployment Steps

### 5.1 Initialize Terraform

```bash
# Initialize Terraform (downloads providers and modules)
terraform init

# You should see:
# - Terraform has been successfully initialized!
```

### 5.2 Validate Configuration

```bash
# Validate syntax
terraform validate

# You should see:
# Success! The configuration is valid.
```

### 5.3 Format Code (Optional)

```bash
# Format all .tf files
terraform fmt -recursive
```

### 5.4 Plan Deployment

```bash
# Create execution plan
terraform plan

# Review the output carefully
# You should see:
# - 1 to add (aws_instance)
# - 0 to change
# - 0 to destroy
```

**Review the plan output for:**
- Instance type: t2.micro
- AMI ID: Correct for your region
- VPC, Subnet, Security Group IDs: Match yours
- Key pair: Correct name

### 5.5 Apply Configuration

```bash
# Apply the configuration
terraform apply

# You'll be prompted to confirm
# Review again and type: yes

# Wait 1-2 minutes for instance creation
```

### 5.6 Save Outputs

```bash
# Get all outputs
terraform output

# Save specific outputs
terraform output instance_public_ip > instance_ip.txt
terraform output application_url

# Example output:
# application_url = "http://54.123.45.67"
# instance_id = "i-0123456789abcdef0"
# instance_public_ip = "54.123.45.67"
```

---

## 6. Verification

### 6.1 Verify Instance Created

```bash
# Check instance status
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress]' \
  --output text \
  --profile default

# Should show: running  54.123.45.67
```

### 6.2 Monitor Deployment Progress

The instance runs **user-data.sh** which clones the repo and executes **IMPLEMENTATION_AUTO.sh**. This takes **5-10 minutes**.

```bash
# SSH into instance
ssh -i bmi-health-tracker-key.pem ubuntu@$(terraform output -raw instance_public_ip)

# Once connected, monitor deployment
sudo tail -f /var/log/cloud-init-output.log

# Watch for:
# - "Starting BMI Health Tracker Deployment"
# - "Cloning application from GitHub..."
# - "Application cloned successfully!"
# - "Running deployment script..."
# - Various installation steps
# - "Deployment completed successfully!"
```

### 6.3 Check Services Status

```bash
# After deployment completes (on EC2 instance)

# Check cloud-init status
cloud-init status

# Check backend service
sudo systemctl status bmi-backend

# Check Nginx
sudo systemctl status nginx

# Check PostgreSQL
sudo systemctl status postgresql

# All should show: active (running)
```

### 6.4 Check Logs

```bash
# Deployment logs
sudo tail -f /var/log/bmi-deployment.log

# Backend logs
sudo tail -f /var/log/bmi-backend.log

# Nginx logs
sudo tail -f /var/log/nginx/bmi-access.log
sudo tail -f /var/log/nginx/bmi-error.log
```

### 6.5 Test Application

```bash
# From local machine
curl http://$(terraform output -raw instance_public_ip)

# Should return HTML

# Test API
curl http://$(terraform output -raw instance_public_ip)/api/health

# Should return: {"status":"ok"} or similar
```

### 6.6 Access in Browser

```bash
# Get URL
terraform output application_url

# Open in browser: http://54.123.45.67
```

**Expected:**
- BMI Health Tracker homepage loads
- Form to enter height and weight
- Calculate BMI button works
- Results display correctly
- Measurements saved to database

---

## 7. Post-Deployment

### 7.1 Test Full Functionality

1. **Calculate BMI**
   - Enter height: 170 cm
   - Enter weight: 70 kg
   - Click Calculate
   - Should show: BMI = 24.2 (Normal weight)

2. **View History**
   - Previous calculations should appear
   - Chart should show trends

3. **Delete Measurements**
   - Test delete functionality
   - Verify removal from list

### 7.2 Set Up SSL (Optional but Recommended)

```bash
# SSH into instance
ssh -i bmi-health-tracker-key.pem ubuntu@<public-ip>

# Install Certbot
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Get certificate (requires a domain name)
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is configured automatically
sudo certbot renew --dry-run
```

### 7.3 Configure Domain Name (Optional)

1. **Add A Record in your DNS**
   - Type: A
   - Name: @ or subdomain
   - Value: Your EC2 public IP
   - TTL: 300

2. **Update Nginx Configuration**

```bash
# SSH into instance
sudo nano /etc/nginx/sites-available/bmi-health-tracker

# Change server_name from IP to domain
server_name yourdomain.com;

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### 7.4 Set Up Monitoring

```bash
# Enable CloudWatch detailed monitoring
aws ec2 monitor-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --profile default

# Create CloudWatch alarm for CPU
aws cloudwatch put-metric-alarm \
  --alarm-name bmi-tracker-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --dimensions Name=InstanceId,Value=$(terraform output -raw instance_id) \
  --profile default
```

### 7.5 Set Up Backups

```bash
# SSH into instance
ssh -i bmi-health-tracker-key.pem ubuntu@<public-ip>

# Create backup script
sudo nano /usr/local/bin/backup-bmi-db.sh

# Add content:
#!/bin/bash
BACKUP_DIR="/home/ubuntu/backups"
mkdir -p $BACKUP_DIR
pg_dump -U bmi_user -d bmidb -h localhost > $BACKUP_DIR/bmidb_$(date +%Y%m%d_%H%M%S).sql
find $BACKUP_DIR -name "bmidb_*.sql" -mtime +7 -delete

# Make executable
sudo chmod +x /usr/local/bin/backup-bmi-db.sh

# Add to crontab (daily at 2 AM)
sudo crontab -e
0 2 * * * /usr/local/bin/backup-bmi-db.sh
```

---

## 8. Troubleshooting

### 8.1 Terraform Init Fails

**Error**: Backend configuration error

**Solution**:
```bash
# Check S3 bucket exists
aws s3 ls s3://your-bucket-name --profile default

# Verify AWS credentials
aws sts get-caller-identity --profile default

# Check backend.tf has correct bucket name and region
```

### 8.2 Terraform Apply Fails

**Error**: UnauthorizedOperation

**Solution**:
```bash
# Check IAM permissions
aws iam get-user --profile default

# Ensure user has EC2, VPC, S3 permissions
```

**Error**: InvalidKeyPair.NotFound

**Solution**:
```bash
# Verify key pair exists
aws ec2 describe-key-pairs --key-names bmi-health-tracker-key --profile default

# If not, create it (see section 3.2)
```

**Error**: InvalidSubnet.ID.NotFound

**Solution**:
```bash
# Verify subnet ID
aws ec2 describe-subnets --subnet-ids subnet-xxxxx --profile default

# Update terraform.tfvars with correct subnet ID
```

### 8.3 Cannot SSH Into Instance

**Error**: Connection timeout

**Solution**:
```bash
# Check security group allows SSH from your IP
aws ec2 describe-security-groups --group-ids sg-xxxxx --profile default

# Add SSH rule if missing
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 22 \
  --cidr $(curl -s ifconfig.me)/32 \
  --profile default

# Verify key permissions
chmod 400 bmi-health-tracker-key.pem
```

**Error**: Permission denied (publickey)

**Solution**:
```bash
# Use correct user
ssh -i bmi-health-tracker-key.pem ubuntu@<ip>  # Not 'ec2-user'

# Verify key file
ls -la bmi-health-tracker-key.pem
```

### 8.4 Application Not Loading

**Check deployment status**:
```bash
# SSH into instance
ssh -i bmi-health-tracker-key.pem ubuntu@<ip>

# Check cloud-init
cloud-init status

# If still running, wait for completion
sudo tail -f /var/log/cloud-init-output.log
```

**Check services**:
```bash
# Backend
sudo systemctl status bmi-backend
sudo journalctl -u bmi-backend -n 50

# Nginx
sudo systemctl status nginx
sudo nginx -t

# PostgreSQL
sudo systemctl status postgresql
```

**Check logs**:
```bash
# Backend errors
sudo tail -100 /var/log/bmi-backend.log

# Nginx errors
sudo tail -100 /var/log/nginx/bmi-error.log

# Deployment errors
sudo tail -100 /var/log/bmi-deployment.log
```

**Restart services**:
```bash
sudo systemctl restart bmi-backend
sudo systemctl restart nginx
```

### 8.5 Database Errors

**Check PostgreSQL**:
```bash
# Status
sudo systemctl status postgresql

# Test connection
psql -U bmi_user -d bmidb -h localhost

# Check tables
psql -U bmi_user -d bmidb -h localhost -c "\dt"

# Check backend .env
cat /home/ubuntu/bmi-health-tracker/backend/.env
```

**Recreate database**:
```bash
# Drop and recreate
sudo -u postgres psql -c "DROP DATABASE IF EXISTS bmidb;"
sudo -u postgres psql -c "CREATE DATABASE bmidb;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bmidb TO bmi_user;"

# Rerun migrations
cd /home/ubuntu/bmi-health-tracker/backend
for f in migrations/*.sql; do
  psql -U bmi_user -d bmidb -h localhost -f "$f"
done

# Restart backend
sudo systemctl restart bmi-backend
```

### 8.6 502 Bad Gateway

**Cause**: Backend not running or not responding

**Solution**:
```bash
# Check backend
sudo systemctl status bmi-backend

# Check if listening on port 3000
sudo netstat -tulpn | grep 3000

# Check backend logs
sudo tail -50 /var/log/bmi-backend.log

# Restart backend
sudo systemctl restart bmi-backend

# Check Nginx proxy config
sudo nginx -t
sudo cat /etc/nginx/sites-available/bmi-health-tracker | grep proxy_pass
```

---

## 9. Cleanup

### 9.1 Destroy Infrastructure

```bash
# From terraform directory
terraform destroy

# Type: yes

# Verify instance terminated
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=bmi-health-tracker-server" \
  --profile default
```

### 9.2 Clean Up AWS Resources

```bash
# Delete S3 bucket (optional - keeps your state history)
aws s3 rb s3://your-bucket-name --force --profile default

# Delete key pair (optional)
aws ec2 delete-key-pair --key-name bmi-health-tracker-key --profile default
rm bmi-health-tracker-key.pem

# Delete security group (optional)
aws ec2 delete-security-group --group-id sg-xxxxx --profile default
```

---

## 10. Summary Checklist

### Pre-Deployment
- [ ] AWS CLI installed and configured
- [ ] Terraform installed
- [ ] EC2 key pair created
- [ ] VPC and public subnet identified
- [ ] Security group created with rules
- [ ] S3 bucket created for state
- [ ] terraform.tfvars configured
- [ ] backend.tf updated with bucket name

### Deployment
- [ ] terraform init successful
- [ ] terraform validate passed
- [ ] terraform plan reviewed
- [ ] terraform apply completed
- [ ] Outputs saved

### Verification
- [ ] Instance running
- [ ] SSH access works
- [ ] Deployment logs show success
- [ ] All services active
- [ ] Application loads in browser
- [ ] BMI calculator works
- [ ] Data persists

### Optional
- [ ] Domain configured
- [ ] SSL certificate installed
- [ ] Monitoring enabled
- [ ] Backups configured

---

## 11. Next Steps

1. **Explore the application**
2. **Review the code** (backend, frontend)
3. **Customize** for your needs
4. **Set up CI/CD** for automatic deployments
5. **Scale** to multi-tier with RDS, ALB, Auto Scaling

---

## 📞 Support

- **Documentation**: [terraform/README.md](terraform/README.md)
- **Quick Reference**: [terraform/QUICK_REFERENCE.md](terraform/QUICK_REFERENCE.md)
- **Architecture**: [terraform/ARCHITECTURE_DIAGRAMS.md](terraform/ARCHITECTURE_DIAGRAMS.md)

---

**Congratulations!** 🎉 You've successfully deployed a full-stack 3-tier application on AWS with Terraform!

---

---

## 🧑‍💻 Author
*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
