#!/bin/bash
set -e

# Log all output to a file
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "========================================"
echo "Starting BMI Health Tracker Deployment"
echo "Time: $(date)"
echo "========================================"

# Note: Removed cloud-init wait to avoid deadlock
# (userdata runs as part of cloud-init final stage)

# Update package lists
echo "Updating package lists..."
apt-get update -qq

# Install required packages
echo "Installing prerequisites..."
apt-get install -y curl wget git

# Clone the application repository
echo "Cloning application from GitHub..."
DEPLOY_DIR="/home/ubuntu/bmi-health-tracker"
git clone https://github.com/md-sarowar-alam/terraform-3-tier-basic.git "$DEPLOY_DIR"

cd "$DEPLOY_DIR"

echo "========================================"
echo "Application cloned successfully!"
echo "Repository: https://github.com/md-sarowar-alam/terraform-3-tier-basic.git"
echo "Location: $DEPLOY_DIR"
echo "========================================"

# Verify critical files exist
if [ ! -f "IMPLEMENTATION_AUTO.sh" ]; then
    echo "ERROR: IMPLEMENTATION_AUTO.sh not found in repository!"
    exit 1
fi

if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "ERROR: backend or frontend directory not found!"
    exit 1
fi

echo "✓ All required files present"

# Set proper ownership
chown -R ubuntu:ubuntu "$DEPLOY_DIR"

# Make deployment script executable (if not already)
chmod +x "$DEPLOY_DIR/IMPLEMENTATION_AUTO.sh"

# Run the deployment script with auto-confirmation
echo "========================================"
echo "Starting automated deployment..."
echo "========================================"

# Export database credentials as environment variables
export DB_NAME="${db_name}"
export DB_USER="${db_user}"
export DB_PASSWORD="${db_password}"

# Run as ubuntu user with auto-yes
# Run deployment with automatic answers
echo "Executing deployment script..."
cd "$DEPLOY_DIR"
echo -e "y\n${db_name}\n${db_user}\n${db_password}\n${db_password}\n" | sudo -u ubuntu ./IMPLEMENTATION_AUTO.sh --fresh 2>&1 | tee /var/log/bmi-deployment.log
# Execute the deployment
# Note: This will run in background and log to /var/log/bmi-deployment.log
# The actual deployment requires the full application code to be present

echo "========================================"
echo "Userdata script completed"
echo "Time: $(date)"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. SSH into the instance"
echo "2. Provide the application source code"
echo "3. Run the deployment script manually if needed"
echo ""
echo "Check logs:"
echo "  sudo tail -f /var/log/user-data.log"
echo "  sudo tail -f /var/log/bmi-deployment.log"
echo ""
echo "Deployment status:"
echo "  Application cloned from: https://github.com/md-sarowar-alam/terraform-3-tier-basic.git"
echo "  Location: $DEPLOY_DIR"
echo "  Deployment script executed"