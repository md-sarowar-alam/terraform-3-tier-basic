# BMI Health Tracker - Infrastructure Overview

## 📖 Project Summary

This project contains **complete Terraform infrastructure** to deploy the BMI Health Tracker 3-tier application on AWS EC2.

### Application Stack
- **Frontend**: React.js + Vite (served by Nginx)
- **Backend**: Node.js + Express API (managed by systemd)
- **Database**: PostgreSQL 
- **Web Server**: Nginx (reverse proxy + static file server)

### Infrastructure
- **Single EC2 Instance**: All components run on one Ubuntu 22.04 server
- **Automated Deployment**: Uses IMPLEMENTATION_AUTO.sh via userdata
- **State Management**: S3 backend for Terraform state
- **Module-Based**: Clean, reusable EC2 module structure

---

## 📂 Directory Structure

```
terraform-3-tier-basic/
├── IMPLEMENTATION_AUTO.sh           # Deployment automation script
├── backend/                         # Node.js backend application
│   ├── src/
│   ├── migrations/
│   └── package.json
├── frontend/                        # React frontend application
│   ├── src/
│   └── package.json
├── database/                        # Database setup scripts
└── terraform/                       # 🎯 TERRAFORM INFRASTRUCTURE
    ├── backend.tf                   # S3 backend configuration
    ├── main.tf                      # Root module - calls EC2 module
    ├── variables.tf                 # Input variables
    ├── outputs.tf                   # Output values
    ├── terraform.tfvars.example     # Example configuration
    ├── .gitignore                   # Git ignore rules
    ├── README.md                    # Detailed documentation
    ├── quick-deploy.sh              # Quick deploy script (Linux/Mac)
    ├── quick-deploy.ps1             # Quick deploy script (Windows)
    └── modules/
        └── ec2/                     # EC2 module
            ├── main.tf              # EC2 instance + userdata
            ├── variables.tf         # Module inputs
            └── outputs.tf           # Module outputs
```

---

## 🎯 What the IMPLEMENTATION_AUTO.sh Script Does

The deployment script automates the **complete setup** of the 3-tier application:

### 1️⃣ **Prerequisites Installation**
- Node.js (via NVM)
- PostgreSQL
- Nginx
- PM2 (process manager)

### 2️⃣ **Database Setup**
- Creates PostgreSQL database (`bmidb`)
- Creates database user (`bmi_user`)
- Configures authentication
- Runs database migrations
- Tests connection

### 3️⃣ **Backend Deployment**
- Creates `.env` file with database credentials
- Installs Node.js dependencies
- Runs database migrations
- Sets up systemd service
- Starts backend API on port 3000

### 4️⃣ **Frontend Deployment**
- Installs dependencies
- Builds React app with Vite
- Deploys to `/var/www/bmi-health-tracker`
- Configures proper permissions

### 5️⃣ **Nginx Configuration**
- Configures reverse proxy for backend API
- Serves static frontend files
- Sets up compression and caching
- Configures security headers
- Auto-detects EC2 public IP

### 6️⃣ **Health Checks**
- Verifies backend API responds
- Tests frontend accessibility
- Confirms database connection
- Checks all services running

---

## 🏗️ Terraform Infrastructure Details

### Root Module ([terraform/](terraform/))

**[main.tf](terraform/main.tf)**
- Configures AWS provider with named profile
- Calls EC2 module with all parameters
- Sets default tags for all resources

**[variables.tf](terraform/variables.tf)**
- Defines all input variables
- Includes validation rules
- Documents defaults and requirements

**[outputs.tf](terraform/outputs.tf)**
- Instance ID, IPs, DNS names
- Application URL
- SSH command
- Deployment notes and instructions

**[backend.tf](terraform/backend.tf)**
- S3 backend for state storage
- Encryption enabled
- No DynamoDB (as requested)
- Uses AWS named profile

### EC2 Module ([terraform/modules/ec2/](terraform/modules/ec2/))

**[main.tf](terraform/modules/ec2/main.tf)**
- Creates EC2 instance with Ubuntu 22.04
- Configures userdata with deployment script
- Sets up IMDSv2 (secure metadata)
- Configures 20GB encrypted EBS volume
- Enables detailed monitoring

**Key Features:**
- **Public IP**: Enabled for public subnet
- **Userdata**: Embeds IMPLEMENTATION_AUTO.sh
- **Security**: IMDSv2, encrypted volumes
- **Tags**: Comprehensive resource tagging

---

## 🚀 Quick Start Guide

### Prerequisites
✅ AWS account with EC2 permissions  
✅ AWS CLI installed and configured  
✅ Terraform >= 1.0 installed  
✅ EC2 key pair created  
✅ S3 bucket for state  
✅ VPC, subnet, security group IDs  

### Step 1: Create S3 Bucket
```bash
aws s3 mb s3://my-terraform-state-bucket --region us-east-1 --profile default
aws s3api put-bucket-versioning --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled --profile default
```

### Step 2: Configure Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
notepad terraform.tfvars  # Windows
```

**Required Values:**
- `aws_profile` - Your AWS CLI profile name
- `key_name` - Your EC2 key pair name
- `vpc_id` - Your VPC ID
- `subnet_id` - Your PUBLIC subnet ID
- `security_group_id` - Security group ID (ports 22, 80, 443)
- `db_password` - Strong database password
- `ami_id` - Ubuntu 22.04 AMI for your region

### Step 3: Update Backend Configuration
Edit `backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket"  # YOUR BUCKET
    key     = "bmi-app/terraform.tfstate"
    region  = "us-east-1"                  # YOUR REGION
    profile = "default"                     # YOUR PROFILE
    encrypt = true
  }
}
```

### Step 4: Deploy

**Option A: Quick Deploy Script (Recommended)**
```bash
# Linux/Mac
chmod +x quick-deploy.sh
./quick-deploy.sh

# Windows PowerShell
.\quick-deploy.ps1
```

**Option B: Manual Terraform Commands**
```bash
terraform init
terraform plan
terraform apply
```

### Step 5: Access Application
```bash
# Get the public IP from outputs
terraform output instance_public_ip

# Access in browser
http://<public-ip>

# Monitor deployment (takes 5-10 minutes)
ssh -i your-key.pem ubuntu@<public-ip>
sudo tail -f /var/log/cloud-init-output.log
```

---

## 🔧 How Userdata Works

The EC2 module's userdata script:

1. **Loads the deployment script** from `IMPLEMENTATION_AUTO.sh`
2. **Creates application structure** in `/home/ubuntu/bmi-health-tracker`
3. **Exports database credentials** as environment variables
4. **Runs deployment script** with auto-confirmation
5. **Logs everything** to `/var/log/user-data.log`

The deployment script then handles all installation and configuration automatically.

---

## 📊 Network Architecture

```
Internet
    ↓
[Internet Gateway]
    ↓
[Public Subnet]
    ↓
[Security Group] ← Port 22 (SSH), 80 (HTTP), 443 (HTTPS)
    ↓
[EC2 Instance: Ubuntu 22.04]
    ├── Nginx :80 → Frontend (React)
    │            └→ /api → Backend :3000
    ├── Backend :3000 → Express API
    └── PostgreSQL :5432 → Database
```

---

## 🔒 Security Features

### Infrastructure Security
- ✅ IMDSv2 enforced (secure metadata access)
- ✅ Encrypted EBS volumes
- ✅ Encrypted S3 state bucket
- ✅ Security group restrictions
- ✅ No hard-coded credentials

### Application Security
- ✅ Database password authentication
- ✅ Nginx security headers
- ✅ Systemd service isolation
- ✅ Proper file permissions

### Best Practices
- 🔐 Use AWS Secrets Manager for production
- 🔐 Enable HTTPS with Let's Encrypt
- 🔐 Restrict SSH to your IP only
- 🔐 Regular security updates

---

## 📝 Important Notes

### 1. Application Source Code
The userdata script expects the application source code. In production:
- **Option 1**: Clone from Git repository
- **Option 2**: Copy from S3 bucket
- **Option 3**: Include in AMI
- **Option 4**: Use deployment artifacts

### 2. Database Password
Currently passed via Terraform variables. For production:
- Use AWS Secrets Manager
- Use AWS Systems Manager Parameter Store
- Rotate passwords regularly

### 3. Single Instance Deployment
This is a **development/testing setup**. For production:
- Use RDS for PostgreSQL
- Add Application Load Balancer
- Implement Auto Scaling
- Use separate frontend S3 + CloudFront
- Add CloudWatch monitoring

### 4. State File Security
The Terraform state contains sensitive data:
- ✅ Stored in encrypted S3 bucket
- ✅ Versioning enabled
- ⚠️ Don't commit to Git
- ⚠️ Limit access with IAM

---

## 🛠️ Useful Commands

### Terraform Operations
```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy everything
terraform destroy

# View outputs
terraform output

# Show state
terraform show
```

### Server Operations
```bash
# SSH into server
ssh -i your-key.pem ubuntu@<public-ip>

# Check deployment progress
sudo tail -f /var/log/cloud-init-output.log
sudo tail -f /var/log/user-data.log

# Check backend service
sudo systemctl status bmi-backend
sudo journalctl -u bmi-backend -f

# Check Nginx
sudo systemctl status nginx
sudo tail -f /var/log/nginx/bmi-*.log

# Database operations
psql -U bmi_user -d bmidb -h localhost
```

---

## 🐛 Troubleshooting

### Issue: Instance not accessible
**Check:**
- Security group allows port 22 from your IP
- Subnet has internet gateway attached
- Public IP is assigned
- Key pair is correct

### Issue: Application not loading
**Check:**
```bash
# Deployment status
cloud-init status

# Deployment logs
sudo tail -f /var/log/cloud-init-output.log

# Backend service
sudo systemctl status bmi-backend
sudo tail -f /var/log/bmi-backend.log

# Nginx
sudo systemctl status nginx
sudo nginx -t
```

### Issue: Database errors
**Check:**
```bash
# PostgreSQL status
sudo systemctl status postgresql

# Database connection
psql -U bmi_user -d bmidb -h localhost

# Backend logs
sudo tail -f /var/log/bmi-backend.log
```

---

## 📚 Module Benefits

### Why Module-Based?
1. **Reusability**: Use EC2 module in multiple projects
2. **Maintainability**: Changes in one place
3. **Testing**: Test modules independently
4. **Composition**: Build complex infrastructure from simple modules
5. **Versioning**: Version control modules separately

### Module Structure
```
modules/ec2/
├── main.tf       # Resource definitions
├── variables.tf  # Input parameters
└── outputs.tf    # Return values
```

This allows you to:
```hcl
module "web_server" {
  source = "./modules/ec2"
  instance_name = "web-server"
  ...
}

module "app_server" {
  source = "./modules/ec2"
  instance_name = "app-server"
  ...
}
```

---

## 🎓 Learning Resources

### Terraform
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Modules](https://www.terraform.io/docs/language/modules/index.html)

### AWS
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)

---

## 📞 Next Steps

After successful deployment:

1. ✅ Test the application thoroughly
2. ✅ Set up SSL/TLS with Let's Encrypt
3. ✅ Configure domain name
4. ✅ Set up CloudWatch monitoring
5. ✅ Implement backup strategy
6. ✅ Create deployment pipeline
7. ✅ Add application monitoring
8. ✅ Security hardening

---

## 📄 Summary

This Terraform infrastructure provides:
- ✅ **Module-based** design for reusability
- ✅ **S3 backend** for state management
- ✅ **AWS named profile** support
- ✅ **Automated deployment** via userdata
- ✅ **Complete 3-tier** application stack
- ✅ **Production-ready** base configuration
- ✅ **Comprehensive documentation**
- ✅ **Quick deploy scripts**

Perfect for deploying the BMI Health Tracker application in AWS! 🚀

---

---

## 🧑‍💻 Author
*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
