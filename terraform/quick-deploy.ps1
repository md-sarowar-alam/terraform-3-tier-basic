# BMI Health Tracker - Quick Deploy Script (PowerShell)
# This script helps you quickly deploy the infrastructure on Windows

$ErrorActionPreference = "Stop"

Write-Host "========================================"
Write-Host "BMI Health Tracker - Quick Deploy"
Write-Host "========================================"
Write-Host ""

# Check if terraform is installed
if (!(Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Terraform is not installed" -ForegroundColor Red
    Write-Host "Please install Terraform from: https://www.terraform.io/downloads"
    exit 1
}

# Check if AWS CLI is installed
if (!(Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: AWS CLI is not installed" -ForegroundColor Red
    Write-Host "Please install AWS CLI from: https://aws.amazon.com/cli/"
    exit 1
}

# Check if terraform.tfvars exists
if (!(Test-Path "terraform.tfvars")) {
    Write-Host "Creating terraform.tfvars from example..."
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Edit terraform.tfvars with your values before continuing!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Required values to update:"
    Write-Host "  - aws_profile (your AWS CLI profile)"
    Write-Host "  - key_name (your EC2 key pair)"
    Write-Host "  - vpc_id"
    Write-Host "  - subnet_id"
    Write-Host "  - security_group_id"
    Write-Host "  - db_password"
    Write-Host "  - ami_id (if not in us-east-1)"
    Write-Host ""
    
    # Open in notepad
    notepad terraform.tfvars
    
    Read-Host "Press Enter after editing terraform.tfvars..."
}

Write-Host ""
Write-Host "Step 1: Validating AWS credentials..."
$awsProfile = (Get-Content terraform.tfvars | Select-String 'aws_profile\s*=\s*"([^"]*)"').Matches.Groups[1].Value
try {
    aws sts get-caller-identity --profile $awsProfile | Out-Null
    Write-Host "✓ AWS credentials valid" -ForegroundColor Green
} catch {
    Write-Host "✗ AWS credentials validation failed" -ForegroundColor Red
    Write-Host "Please configure your AWS profile: aws configure --profile $awsProfile"
    exit 1
}

Write-Host ""
Write-Host "Step 2: Checking S3 backend bucket..."
$s3Bucket = (Get-Content backend.tf | Select-String 'bucket\s*=\s*"([^"]*)"' | Where-Object { $_ -notmatch '^\s*#' }).Matches.Groups[1].Value
try {
    aws s3 ls "s3://$s3Bucket" --profile $awsProfile | Out-Null
    Write-Host "✓ S3 bucket exists: $s3Bucket" -ForegroundColor Green
} catch {
    Write-Host "⚠️  S3 bucket does not exist: $s3Bucket" -ForegroundColor Yellow
    $createBucket = Read-Host "Create bucket? (y/n)"
    if ($createBucket -eq 'y') {
        $awsRegion = (Get-Content terraform.tfvars | Select-String 'aws_region\s*=\s*"([^"]*)"').Matches.Groups[1].Value
        aws s3 mb "s3://$s3Bucket" --region $awsRegion --profile $awsProfile
        aws s3api put-bucket-versioning --bucket $s3Bucket --versioning-configuration Status=Enabled --profile $awsProfile
        Write-Host "✓ Bucket created and versioning enabled" -ForegroundColor Green
    } else {
        Write-Host "Please create the S3 bucket manually or update backend.tf"
        exit 1
    }
}

Write-Host ""
Write-Host "Step 3: Initializing Terraform..."
terraform init

Write-Host ""
Write-Host "Step 4: Validating Terraform configuration..."
terraform validate

Write-Host ""
Write-Host "Step 5: Planning deployment..."
terraform plan -out=tfplan

Write-Host ""
Write-Host "========================================"
Write-Host "Review the plan above carefully"
Write-Host "========================================"
Write-Host ""
$applyConfirm = Read-Host "Do you want to apply this plan? (yes/no)"

if ($applyConfirm -eq "yes") {
    Write-Host ""
    Write-Host "Step 6: Applying Terraform configuration..."
    terraform apply tfplan
    
    Write-Host ""
    Write-Host "========================================"
    Write-Host "Deployment Complete!"
    Write-Host "========================================"
    Write-Host ""
    
    # Get outputs
    try {
        $publicIP = terraform output -raw instance_public_ip
    } catch {
        $publicIP = "N/A"
    }
    
    Write-Host "Application URL: http://$publicIP" -ForegroundColor Green
    Write-Host ""
    Write-Host "⏳ The application is deploying automatically via userdata."
    Write-Host "   This may take 5-10 minutes. Monitor progress:"
    Write-Host ""
    Write-Host "   ssh -i <your-key.pem> ubuntu@$publicIP"
    Write-Host "   sudo tail -f /var/log/cloud-init-output.log"
    Write-Host ""
    
    # Cleanup plan file
    Remove-Item tfplan -ErrorAction SilentlyContinue
} else {
    Write-Host "Deployment cancelled"
    Remove-Item tfplan -ErrorAction SilentlyContinue
    exit 0
}
