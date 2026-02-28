#!/bin/bash

set -e

echo "========================================="
echo "     DEVOPS CI/CD AUTO BOOTSTRAP        "
echo "========================================="

# -----------------------------
# System Update
# -----------------------------
echo "Updating system..."
sudo apt update -y
sudo apt upgrade -y

# -----------------------------
# Install Required Packages
# -----------------------------
echo "Installing required packages..."
sudo apt install -y curl git ufw gnupg2 ca-certificates lsb-release apt-transport-https

# -----------------------------
# Install Docker (Official Method)
# -----------------------------
echo "Installing Docker..."

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER

# -----------------------------
# Install Java (Required for Jenkins)
# -----------------------------
echo "Installing Java..."
sudo apt install -y openjdk-17-jdk

# -----------------------------
# Clean Old Jenkins Config (Important)
# -----------------------------
echo "Cleaning old Jenkins configs..."
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo rm -f /usr/share/keyrings/jenkins-keyring.*

# -----------------------------
# Install Jenkins (Ubuntu 24 Safe)
# -----------------------------
echo "Installing Jenkins..."

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
sudo gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins

sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# -----------------------------
# Configure Firewall
# -----------------------------
echo "Configuring firewall..."

sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 8080
sudo ufw --force enable

# -----------------------------
# Create Static Web App
# -----------------------------
echo "Creating static web app..."

mkdir -p ~/static-webapp
cd ~/static-webapp

cat <<EOF > index.html
<!DOCTYPE html>
<html>
<head>
<title>DevOps Deployment</title>
<style>
body { text-align:center; font-family:Arial; background:#f4f4f4; }
h1 { color:#2c3e50; }
</style>
</head>
<body>
<h1>🚀 Successfully Deployed via Jenkins + Docker</h1>
<p>Fully Automated Bootstrap Script</p>
</body>
</html>
EOF

# -----------------------------
# Create Dockerfile
# -----------------------------
cat <<EOF > Dockerfile
FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# -----------------------------
# Build & Run Container
# -----------------------------
echo "Building Docker image..."
sudo docker build -t static-webapp .

echo "Running container..."
sudo docker stop static-webapp || true
sudo docker rm static-webapp || true
sudo docker run -d -p 80:80 --name static-webapp static-webapp

# -----------------------------
# Show Access Info
# -----------------------------
PUBLIC_IP=$(curl -s ifconfig.me)

echo "========================================="
echo "        🚀 SETUP COMPLETED SUCCESSFULLY"
echo "-----------------------------------------"
echo "Web App  : http://$PUBLIC_IP"
echo "Jenkins  : http://$PUBLIC_IP:8080"
echo "========================================="
