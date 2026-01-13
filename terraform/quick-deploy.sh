#!/bin/bash

################################################################################
# BMI Health Tracker - Quick Deploy Script
# This script helps you quickly deploy the infrastructure
################################################################################

set -e

echo "========================================"
echo "BMI Health Tracker - Quick Deploy"
echo "========================================"
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "ERROR: Terraform is not installed"
    echo "Please install Terraform from: https://www.terraform.io/downloads"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed"
    echo "Please install AWS CLI from: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo ""
    echo "⚠️  IMPORTANT: Edit terraform.tfvars with your values before continuing!"
    echo ""
    echo "Required values to update:"
    echo "  - aws_profile (your AWS CLI profile)"
    echo "  - key_name (your EC2 key pair)"
    echo "  - vpc_id"
    echo "  - subnet_id"
    echo "  - security_group_id"
    echo "  - db_password"
    echo "  - ami_id (if not in us-east-1)"
    echo ""
    read -p "Press Enter after editing terraform.tfvars..."
fi

echo ""
echo "Step 1: Validating AWS credentials..."
AWS_PROFILE=$(grep '^aws_profile' terraform.tfvars | cut -d'"' -f2)
if aws sts get-caller-identity --profile "$AWS_PROFILE" &> /dev/null; then
    echo "✓ AWS credentials valid"
else
    echo "✗ AWS credentials validation failed"
    echo "Please configure your AWS profile: aws configure --profile $AWS_PROFILE"
    exit 1
fi

echo ""
echo "Step 2: Checking S3 backend bucket..."
S3_BUCKET=$(grep 'bucket' backend.tf | grep -v '#' | cut -d'"' -f2)
if aws s3 ls "s3://$S3_BUCKET" --profile "$AWS_PROFILE" &> /dev/null; then
    echo "✓ S3 bucket exists: $S3_BUCKET"
else
    echo "⚠️  S3 bucket does not exist: $S3_BUCKET"
    read -p "Create bucket? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        AWS_REGION=$(grep '^aws_region' terraform.tfvars | cut -d'"' -f2)
        aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION" --profile "$AWS_PROFILE"
        aws s3api put-bucket-versioning --bucket "$S3_BUCKET" --versioning-configuration Status=Enabled --profile "$AWS_PROFILE"
        echo "✓ Bucket created and versioning enabled"
    else
        echo "Please create the S3 bucket manually or update backend.tf"
        exit 1
    fi
fi

echo ""
echo "Step 3: Initializing Terraform..."
terraform init

echo ""
echo "Step 4: Validating Terraform configuration..."
terraform validate

echo ""
echo "Step 5: Planning deployment..."
terraform plan -out=tfplan

echo ""
echo "========================================"
echo "Review the plan above carefully"
echo "========================================"
echo ""
read -p "Do you want to apply this plan? (yes/no): " APPLY_CONFIRM

if [ "$APPLY_CONFIRM" = "yes" ]; then
    echo ""
    echo "Step 6: Applying Terraform configuration..."
    terraform apply tfplan
    
    echo ""
    echo "========================================"
    echo "Deployment Complete!"
    echo "========================================"
    echo ""
    
    # Get outputs
    PUBLIC_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "N/A")
    
    echo "Application URL: http://$PUBLIC_IP"
    echo ""
    echo "⏳ The application is deploying automatically via userdata."
    echo "   This may take 5-10 minutes. Monitor progress:"
    echo ""
    echo "   ssh -i <your-key.pem> ubuntu@$PUBLIC_IP"
    echo "   sudo tail -f /var/log/cloud-init-output.log"
    echo ""
    
    # Cleanup plan file
    rm -f tfplan
else
    echo "Deployment cancelled"
    rm -f tfplan
    exit 0
fi
