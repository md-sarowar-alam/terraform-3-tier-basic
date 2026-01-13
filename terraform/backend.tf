# S3 Backend Configuration for Terraform State
# This backend stores the Terraform state in an S3 bucket
# Before running terraform init, ensure the S3 bucket exists

terraform {
  backend "s3" {
    bucket  = "my-terraform-state-bucket"  # Change this to your bucket name
    key     = "bmi-app/terraform.tfstate"
    region  = "us-east-1"                  # Change to your region
    profile = "default"                     # Change to your AWS profile name
    
    # Enable encryption
    encrypt = true
    
    # Note: DynamoDB table is not used (as per requirements)
  }
}
