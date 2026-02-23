# BMI Health Tracker - Full Stack Application with Terraform Infrastructure

A complete 3-tier web application for tracking Body Mass Index (BMI) measurements, with automated AWS deployment using Terraform.

## 📋 Project Overview

This project consists of two main parts:

1. **BMI Health Tracker Application** - A full-stack web application
   - **Frontend**: React + Vite
   - **Backend**: Node.js + Express API
   - **Database**: PostgreSQL

2. **Terraform Infrastructure** - Automated AWS EC2 deployment
   - Module-based architecture
   - Automated deployment via userdata
   - S3 backend for state management

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       AWS EC2 Instance                          │
│                      (Ubuntu 22.04 LTS)                         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Nginx (Port 80)                                           │ │
│  │  • Static files serving (React app)                        │ │
│  │  • Reverse proxy to backend API                            │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Frontend - React Application                              │ │
│  │  Location: /var/www/bmi-health-tracker                     │ │
│  │  • BMI Calculator                                           │ │
│  │  • Measurement History                                      │ │
│  │  • Trend Charts (Chart.js)                                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Backend API - Node.js + Express (Port 3000)               │ │
│  │  Service: systemd (bmi-backend.service)                    │ │
│  │  • RESTful API endpoints                                    │ │
│  │  • BMI calculations                                         │ │
│  │  • PostgreSQL integration                                   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  PostgreSQL Database (Port 5432)                           │ │
│  │  Database: bmidb                                            │ │
│  │  • User measurements storage                                │ │
│  │  • Automated migrations                                     │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## 📂 Project Structure

```
terraform-3-tier-basic/
├── 📱 Application
│   ├── backend/                      # Node.js Backend API
│   │   ├── src/
│   │   │   ├── server.js            # Express server
│   │   │   ├── routes.js            # API routes
│   │   │   ├── db.js                # Database connection
│   │   │   ├── calculations.js      # BMI calculations
│   │   │   └── metrics.js           # Health metrics
│   │   ├── migrations/              # Database migrations
│   │   │   ├── 001_create_measurements.sql
│   │   │   └── 002_add_measurement_date.sql
│   │   └── package.json
│   │
│   ├── frontend/                    # React Frontend
│   │   ├── src/
│   │   │   ├── main.jsx            # Entry point
│   │   │   ├── App.jsx             # Main component
│   │   │   ├── api.js              # API client
│   │   │   └── components/
│   │   │       ├── MeasurementForm.jsx
│   │   │       └── TrendChart.jsx
│   │   ├── index.html
│   │   ├── vite.config.js
│   │   └── package.json
│   │
│   └── database/                    # Database scripts
│       └── setup-database.sh
│
├── 🚀 Deployment
│   └── IMPLEMENTATION_AUTO.sh       # Automated deployment script
│
└── 🏗️ Infrastructure
    └── terraform/                   # Terraform configuration
        ├── main.tf                  # Root module
        ├── variables.tf             # Input variables
        ├── outputs.tf               # Outputs
        ├── backend.tf               # S3 backend config
        ├── terraform.tfvars.example # Example config
        ├── modules/
        │   └── ec2/                 # EC2 module
        │       ├── main.tf
        │       ├── variables.tf
        │       ├── outputs.tf
        │       └── user-data.sh     # Bootstrap script
        └── 📚 Documentation
            ├── README.md
            ├── START_HERE.md
            ├── INFRASTRUCTURE_OVERVIEW.md
            ├── ARCHITECTURE_DIAGRAMS.md
            └── QUICK_REFERENCE.md
```

## ✨ Features

### Application Features
- ✅ **BMI Calculator** - Calculate Body Mass Index
- ✅ **Measurement Tracking** - Store and view history
- ✅ **Data Visualization** - Charts showing trends over time
- ✅ **Health Categories** - Underweight, Normal, Overweight, Obese
- ✅ **Responsive Design** - Works on mobile and desktop
- ✅ **RESTful API** - Clean API endpoints

### Infrastructure Features
- ✅ **Automated Deployment** - One-command infrastructure setup
- ✅ **Module-Based** - Reusable Terraform modules
- ✅ **AWS Best Practices** - Security, encryption, monitoring
- ✅ **Git Integration** - Clones application from GitHub
- ✅ **State Management** - S3 backend for Terraform state
- ✅ **Comprehensive Docs** - 5+ documentation files

## 🚀 Quick Start

### Prerequisites

```bash
# Required
✅ AWS Account with appropriate permissions
✅ AWS CLI installed and configured
✅ Terraform >= 1.0 installed
✅ EC2 key pair created
✅ VPC, public subnet, and security group ready

# For local development
✅ Node.js >= 18.x
✅ PostgreSQL >= 13
✅ Git
```

### Deploy to AWS (Production)

```bash
# 1. Clone the repository
git clone https://github.com/md-sarowar-alam/terraform-3-tier-basic.git
cd terraform-3-tier-basic

# 2. Navigate to terraform directory
cd terraform

# 3. Create S3 bucket for Terraform state
aws s3 mb s3://my-terraform-state-bucket --region us-east-1 --profile default

# 4. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS details

# 5. Update backend.tf with your S3 bucket name

# 6. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 7. Get application URL
terraform output application_url
# Visit: http://<public-ip>
```

**⏳ Deployment takes 5-10 minutes** - The application will be automatically installed and configured.

### Local Development

```bash
# 1. Set up database
cd database
./setup-database.sh

# 2. Start backend
cd ../backend
npm install
cp .env.example .env  # Configure database credentials
npm start

# 3. Start frontend (in another terminal)
cd ../frontend
npm install
npm run dev

# Visit: http://localhost:5173
```

## 📚 Documentation

### For Deployment

- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - Step-by-step deployment guide
- **[terraform/README.md](terraform/README.md)** - Terraform setup instructions
- **[terraform/START_HERE.md](terraform/START_HERE.md)** - Quick overview

### For Understanding

- **[terraform/INFRASTRUCTURE_OVERVIEW.md](terraform/INFRASTRUCTURE_OVERVIEW.md)** - Detailed infrastructure explanation
- **[terraform/ARCHITECTURE_DIAGRAMS.md](terraform/ARCHITECTURE_DIAGRAMS.md)** - Visual architecture diagrams
- **[terraform/QUICK_REFERENCE.md](terraform/QUICK_REFERENCE.md)** - Commands and troubleshooting

## 🔐 Security

### Infrastructure Security
- ✅ IMDSv2 enforced on EC2 instances
- ✅ Encrypted EBS volumes
- ✅ Encrypted S3 state bucket
- ✅ Security group restrictions
- ✅ SSH key-based authentication

### Application Security
- ✅ PostgreSQL password authentication
- ✅ Environment variable for secrets
- ✅ Nginx security headers
- ✅ Systemd service isolation
- ✅ CORS configuration

### Security Group Requirements

| Type | Protocol | Port | Source | Purpose |
|------|----------|------|--------|---------|
| SSH | TCP | 22 | Your IP | SSH access |
| HTTP | TCP | 80 | 0.0.0.0/0 | Web access |
| HTTPS | TCP | 443 | 0.0.0.0/0 | SSL (optional) |

## 🛠️ Technology Stack

### Frontend
- **Framework**: React 18
- **Build Tool**: Vite 5
- **HTTP Client**: Axios
- **Charts**: Chart.js + react-chartjs-2
- **Styling**: CSS

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database Driver**: node-postgres (pg)
- **Middleware**: CORS, body-parser
- **Environment**: dotenv

### Database
- **Database**: PostgreSQL 13+
- **Migrations**: SQL scripts
- **Authentication**: Password-based

### Infrastructure
- **IaC**: Terraform
- **Cloud**: AWS (EC2, S3, VPC)
- **Web Server**: Nginx
- **Process Manager**: systemd
- **Automation**: Bash scripts

## 📊 API Endpoints

```
GET    /api/measurements          # Get all measurements
POST   /api/measurements          # Create new measurement
GET    /api/measurements/:id      # Get specific measurement
PUT    /api/measurements/:id      # Update measurement
DELETE /api/measurements/:id      # Delete measurement
GET    /api/health                # Health check
```

## 🔧 Configuration

### Backend Environment Variables

```env
# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/bmidb
DB_USER=bmi_user
DB_PASSWORD=your_password
DB_NAME=bmidb
DB_HOST=localhost
DB_PORT=5432

# Server Configuration
PORT=3000
NODE_ENV=production

# CORS Configuration
CORS_ORIGIN=*
```

### Terraform Variables

```hcl
aws_region        = "us-east-1"
aws_profile       = "default"
instance_name     = "bmi-health-tracker-server"
instance_type     = "t2.micro"
key_name          = "my-keypair"
vpc_id            = "vpc-xxxxx"
subnet_id         = "subnet-xxxxx"
security_group_id = "sg-xxxxx"
db_password       = "SecurePassword123!"
```

## 🐛 Troubleshooting

### Application Not Loading

```bash
# SSH into instance
ssh -i your-key.pem ubuntu@<public-ip>

# Check deployment progress
sudo tail -f /var/log/cloud-init-output.log

# Check services
sudo systemctl status bmi-backend
sudo systemctl status nginx
sudo systemctl status postgresql

# View logs
sudo tail -f /var/log/bmi-backend.log
sudo tail -f /var/log/nginx/bmi-error.log
```

### Database Connection Issues

```bash
# Test PostgreSQL
sudo systemctl status postgresql

# Test connection
psql -U bmi_user -d bmidb -h localhost

# Check backend logs
sudo tail -f /var/log/bmi-backend.log
```

### Frontend Build Issues

```bash
# Rebuild frontend
cd /home/ubuntu/bmi-health-tracker/frontend
npm install
npm run build
sudo rm -rf /var/www/bmi-health-tracker/*
sudo cp -r dist/* /var/www/bmi-health-tracker/
sudo systemctl restart nginx
```

## 📈 Monitoring

### Check Service Status

```bash
# All services
sudo systemctl status bmi-backend nginx postgresql

# Backend logs
sudo journalctl -u bmi-backend -f

# Nginx logs
sudo tail -f /var/log/nginx/bmi-access.log
sudo tail -f /var/log/nginx/bmi-error.log

# System resources
htop
df -h
free -h
```

## 🚧 Production Recommendations

For production deployment, consider:

- [ ] Use AWS RDS for PostgreSQL
- [ ] Add Application Load Balancer
- [ ] Implement Auto Scaling
- [ ] Use CloudFront for frontend
- [ ] Enable SSL/TLS with ACM
- [ ] Set up CloudWatch monitoring
- [ ] Implement automated backups
- [ ] Use AWS Secrets Manager
- [ ] Add CI/CD pipeline
- [ ] Enable CloudWatch Logs
- [ ] Implement health checks
- [ ] Set up alerting

## 📞 Support

- **Documentation**: See [terraform/](terraform/) directory
- **Issues**: Create a GitHub issue
- **Logs**: Check `/var/log/` on EC2 instance

## 🔗 Links

- **Repository**: https://github.com/md-sarowar-alam/terraform-3-tier-basic
- **Terraform Docs**: [terraform/README.md](terraform/README.md)
- **Implementation Guide**: [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)

---

---

## 🧑‍💻 Author
*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
