#!/bin/bash

set -e

echo "==============================="
echo "   DEVOPS AUTO SETUP STARTED   "
echo "==============================="

# Update System
echo "Updating system..."
sudo apt update -y

# Install Required Packages
echo "Installing Docker, Git, Java, Curl..."
sudo apt install -y docker.io git curl openjdk-17-jdk ufw

# Start and Enable Docker
echo "Configuring Docker..."
sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker ubuntu

# Install Jenkins
echo "Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins

sudo systemctl start jenkins
sudo systemctl enable jenkins

sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Configure Firewall
echo "Configuring Firewall..."
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 8080
sudo ufw --force enable

# Create Static Web App
echo "Creating Sample Web Application..."
mkdir -p ~/static-webapp
cd ~/static-webapp

cat <<EOF > index.html
<!DOCTYPE html>
<html>
<head>
    <title>DevOps Pipeline</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>🚀 Deployed using Jenkins + Docker + AWS</h1>
    <p>Fully Automated CI/CD Pipeline</p>
    <script src="script.js"></script>
</body>
</html>
EOF

cat <<EOF > style.css
body {
    text-align: center;
    font-family: Arial;
    background-color: #f4f4f4;
}
h1 {
    color: #2c3e50;
}
p {
    font-size: 18px;
}
EOF

cat <<EOF > script.js
console.log("Deployment Successful!");
EOF

# Create Dockerfile
echo "Creating Dockerfile..."
cat <<EOF > Dockerfile
FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Build Docker Image
echo "Building Docker Image..."
sudo docker build -t static-webapp .

# Run Container
echo "Deploying Container..."
sudo docker stop static-webapp || true
sudo docker rm static-webapp || true
sudo docker run -d -p 80:80 --name static-webapp static-webapp

PUBLIC_IP=$(curl -s ifconfig.me)

echo "======================================="
echo "  🚀 DEPLOYMENT COMPLETED SUCCESSFULLY"
echo "---------------------------------------"
echo "  Web App  : http://$PUBLIC_IP"
echo "  Jenkins  : http://$PUBLIC_IP:8080"
echo "======================================="
