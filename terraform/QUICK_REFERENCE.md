# 🚀 Quick Reference Guide

## ⚡ Quick Commands

### Initial Setup
```bash
# 1. Create S3 bucket
aws s3 mb s3://my-terraform-state-bucket --region us-east-1 --profile default

# 2. Copy and edit variables
cd terraform
cp terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars  # Edit with your values

# 3. Update backend.tf with your bucket name
```

### Deploy
```bash
# Quick deploy (recommended)
.\quick-deploy.ps1         # Windows
./quick-deploy.sh          # Linux/Mac

# Or manual
terraform init
terraform plan
terraform apply
```

### Monitor Deployment
```bash
# Get public IP
terraform output instance_public_ip

# SSH into instance
ssh -i your-key.pem ubuntu@<public-ip>

# Watch deployment
sudo tail -f /var/log/cloud-init-output.log
sudo tail -f /var/log/bmi-deployment.log
```

### Check Status
```bash
# On EC2 instance
sudo systemctl status bmi-backend
sudo systemctl status nginx
sudo systemctl status postgresql

# View logs
sudo tail -f /var/log/bmi-backend.log
sudo tail -f /var/log/nginx/bmi-error.log
```

### Cleanup
```bash
terraform destroy
```

---

## 📝 Required Information Checklist

Before deployment, gather:

- [ ] AWS CLI profile name: `_____________`
- [ ] EC2 key pair name: `_____________`
- [ ] VPC ID: `vpc-_____________`
- [ ] Public Subnet ID: `subnet-_____________`
- [ ] Security Group ID: `sg-_____________`
- [ ] Database password: `_____________` (min 8 chars)
- [ ] AWS Region: `_____________` (default: us-east-1)
- [ ] S3 bucket for state: `_____________`

---

## 🔐 Security Group Rules

Your security group MUST allow:

| Type | Protocol | Port | Source | Description |
|------|----------|------|--------|-------------|
| SSH | TCP | 22 | Your IP | SSH access |
| HTTP | TCP | 80 | 0.0.0.0/0 | Web access |
| HTTPS | TCP | 443 | 0.0.0.0/0 | HTTPS (future) |

---

## 🎯 terraform.tfvars Template

```hcl
aws_region        = "us-east-1"
aws_profile       = "default"
environment       = "dev"

instance_name     = "bmi-health-tracker-server"
instance_type     = "t2.micro"
ami_id            = "ami-0e86e20dae9224db8"  # Ubuntu 22.04 us-east-1
key_name          = "my-keypair"

vpc_id            = "vpc-xxxxxxxxxxxxxxxxx"
subnet_id         = "subnet-xxxxxxxxxxxxxxxxx"
security_group_id = "sg-xxxxxxxxxxxxxxxxx"

db_name           = "bmidb"
db_user           = "bmi_user"
db_password       = "YourSecurePassword123!"

deployment_script_path = "../IMPLEMENTATION_AUTO.sh"

additional_tags = {
  Owner = "Your Name"
}
```

---

## 🌍 Ubuntu 22.04 AMI IDs by Region

```
us-east-1      : ami-0e86e20dae9224db8
us-east-2      : ami-0ea3c35c5c3284d82
us-west-1      : ami-0d5ae5525eb033d0a
us-west-2      : ami-03f65b8614a860c29
eu-west-1      : ami-0905a3c97561e0b69
eu-west-2      : ami-0b9932f4918a00c4f
eu-central-1   : ami-0084a47cc718c111a
ap-south-1     : ami-0f58b397bc5c1f2e8
ap-southeast-1 : ami-0dc2d3e4c0f9ebd18
ap-southeast-2 : ami-0310483fb2b488153
ap-northeast-1 : ami-0d52744d6551d851e
```

**Find latest:**
```bash
aws ec2 describe-images --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'sort_by(Images, &CreationDate)[-1].[ImageId,Name]' \
  --output text --region YOUR_REGION --profile YOUR_PROFILE
```

---

## 📊 Terraform Commands Reference

```bash
# Initialize
terraform init                 # Download providers & modules
terraform init -upgrade        # Upgrade providers

# Planning
terraform plan                 # Show changes
terraform plan -out=tfplan     # Save plan to file

# Applying
terraform apply                # Apply with prompt
terraform apply tfplan         # Apply saved plan
terraform apply -auto-approve  # Apply without prompt

# Inspecting
terraform show                 # Show current state
terraform output               # Show all outputs
terraform output instance_ip   # Show specific output
terraform state list           # List resources
terraform state show <resource>  # Show resource details

# Destroying
terraform destroy              # Destroy all resources
terraform destroy -target=...  # Destroy specific resource

# Formatting & Validation
terraform fmt                  # Format .tf files
terraform fmt -recursive       # Format recursively
terraform validate             # Validate syntax

# State Management
terraform state pull           # Download state
terraform state push           # Upload state
terraform refresh              # Refresh state from AWS
```

---

## 🔍 Troubleshooting Quick Fixes

### "Terraform init fails"
```bash
# Check backend.tf configuration
# Verify S3 bucket exists
aws s3 ls s3://your-bucket --profile your-profile
```

### "Plan shows no changes but resource doesn't exist"
```bash
# Refresh state
terraform refresh

# Or remove from state and re-import
terraform state rm module.ec2_instance.aws_instance.this
terraform import module.ec2_instance.aws_instance.this i-xxxxx
```

### "Apply fails with credentials error"
```bash
# Test AWS credentials
aws sts get-caller-identity --profile your-profile

# Reconfigure if needed
aws configure --profile your-profile
```

### "Can't connect to instance"
```bash
# Check security group
aws ec2 describe-security-groups --group-ids sg-xxxxx --profile your-profile

# Check instance status
aws ec2 describe-instances --instance-ids i-xxxxx --profile your-profile

# Verify key permissions
chmod 400 your-key.pem
```

### "Application not loading"
```bash
# SSH into instance
ssh -i your-key.pem ubuntu@<ip>

# Check deployment status
cloud-init status
sudo tail -f /var/log/cloud-init-output.log

# Check services
sudo systemctl status bmi-backend
sudo systemctl status nginx
sudo systemctl status postgresql

# View service logs
sudo journalctl -u bmi-backend -f
sudo tail -f /var/log/nginx/bmi-error.log

# Restart services if needed
sudo systemctl restart bmi-backend
sudo systemctl restart nginx
```

### "Database connection errors"
```bash
# On EC2 instance
# Check PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -c "\l"

# Test connection
psql -U bmi_user -d bmidb -h localhost

# Check backend environment
cat /home/ubuntu/bmi-health-tracker/backend/.env

# View backend logs
sudo tail -f /var/log/bmi-backend.log
```

---

## 📂 Important File Locations

### On Your Local Machine
```
terraform/
├── terraform.tfvars        ← Your configuration (DO NOT COMMIT!)
├── backend.tf              ← Edit S3 bucket name
├── main.tf                 ← Root module
└── modules/ec2/main.tf     ← EC2 configuration
```

### On EC2 Instance
```
/home/ubuntu/bmi-health-tracker/     ← Application source
/var/www/bmi-health-tracker/         ← Frontend deployment
/var/log/cloud-init-output.log       ← Deployment logs
/var/log/bmi-backend.log             ← Backend logs
/var/log/nginx/bmi-*.log             ← Nginx logs
/etc/nginx/sites-available/...       ← Nginx config
/etc/systemd/system/bmi-backend.service  ← Backend service
```

---

## 🎓 Common Tasks

### Update Application Code
```bash
# SSH into instance
ssh -i your-key.pem ubuntu@<ip>

# Update code (if using git)
cd /home/ubuntu/bmi-health-tracker
git pull

# Rebuild frontend
cd frontend
npm install
npm run build
sudo rm -rf /var/www/bmi-health-tracker/*
sudo cp -r dist/* /var/www/bmi-health-tracker/

# Restart backend
sudo systemctl restart bmi-backend
```

### Enable SSL with Let's Encrypt
```bash
# On EC2 instance
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Get certificate (requires domain name)
sudo certbot --nginx -d yourdomain.com

# Auto-renewal is set up automatically
sudo certbot renew --dry-run
```

### Backup Database
```bash
# On EC2 instance
pg_dump -U bmi_user -d bmidb -h localhost > backup_$(date +%Y%m%d).sql

# Download backup
# On local machine:
scp -i your-key.pem ubuntu@<ip>:backup_*.sql ./
```

### View Resource Usage
```bash
# On EC2 instance
htop                    # Interactive process viewer
df -h                   # Disk usage
free -h                 # Memory usage
systemctl status        # All services
journalctl -xe          # System logs
```

### Change Instance Type
```bash
# In terraform.tfvars
instance_type = "t2.small"  # Change from t2.micro

# Apply changes
terraform apply
```

---

## ⚡ One-Liner Helpers

```bash
# Get all Terraform outputs as JSON
terraform output -json | jq

# SSH with one command (replace values)
ssh -i ~/.ssh/my-key.pem ubuntu@$(terraform output -raw instance_public_ip)

# Open application in browser (macOS)
open "http://$(terraform output -raw instance_public_ip)"

# Open application in browser (Windows)
start "http://$(terraform output -raw instance_public_ip)"

# Watch backend logs remotely
ssh -i your-key.pem ubuntu@<ip> "sudo tail -f /var/log/bmi-backend.log"

# Check if application is responding
curl -I http://$(terraform output -raw instance_public_ip)

# Get instance metadata (on EC2)
curl -H "X-aws-ec2-metadata-token: $(curl -X PUT 'http://169.254.169.254/latest/api/token' -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600')" http://169.254.169.254/latest/meta-data/
```

---

## 📞 Getting Help

### Check Documentation
- Main README: `terraform/README.md`
- Infrastructure Overview: `terraform/INFRASTRUCTURE_OVERVIEW.md`
- Architecture Diagrams: `terraform/ARCHITECTURE_DIAGRAMS.md`

### View Logs
```bash
# Deployment
sudo tail -f /var/log/cloud-init-output.log
sudo tail -f /var/log/bmi-deployment.log

# Application
sudo journalctl -u bmi-backend -f
sudo tail -f /var/log/bmi-backend.log

# Web Server
sudo tail -f /var/log/nginx/bmi-error.log
sudo tail -f /var/log/nginx/bmi-access.log
```

### Test Connectivity
```bash
# From local machine
ping <public-ip>
telnet <public-ip> 80
curl http://<public-ip>

# On EC2
curl localhost
curl localhost:3000/api/measurements
psql -U bmi_user -d bmidb -h localhost -c "SELECT version();"
```

---

## ✅ Post-Deployment Checklist

After `terraform apply` completes:

- [ ] Wait 5-10 minutes for deployment to complete
- [ ] Check application URL in browser
- [ ] SSH into instance and verify logs
- [ ] Test BMI calculator functionality
- [ ] Verify backend API responds
- [ ] Check database connectivity
- [ ] Review security group rules
- [ ] Set up SSL certificate (if using domain)
- [ ] Configure CloudWatch monitoring
- [ ] Set up database backups
- [ ] Document instance details

---

## 🎯 Quick Wins

### Improve Performance
```bash
# Upgrade instance type
instance_type = "t3.small"  # Better performance than t2.micro
```

### Enhance Security
```bash
# Restrict SSH to your IP only in security group
# Enable HTTPS with Let's Encrypt
# Rotate database password regularly
# Use AWS Secrets Manager for production
```

### Monitor Better
```bash
# Enable CloudWatch detailed monitoring (already enabled)
# Set up CloudWatch alarms
# Use CloudWatch Logs agent
# Monitor costs with AWS Cost Explorer
```

---

**Need more help?** Check the full documentation in the `terraform/` directory! 📚

---

## 🧑‍💻 Author
**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: [linkedin.com/in/sarowar](https://www.linkedin.com/in/sarowar/)

---
