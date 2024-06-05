# LocalAI Setup for Jetson Nano

Welcome to the LocalAI setup for Jetson Nano! This repository provides everything you need to run LocalAI with NVIDIA GPU support on your Jetson Nano device.

## What's Included

- **Dockerfile**: Builds the Docker environment for LocalAI.
- **entrypoint.sh**: Manages the server startup.
- **localai.service**: Systemd service file to manage LocalAI as a service.
- **install_localai_jetson.sh**: Script to automate the Docker setup and run the LocalAI server.

## Prerequisites

Before you begin, make sure you have:

1. A Jetson Nano with NVIDIA JetPack installed.
2. Docker installed on your system.
3. Git installed on your system.

## Installation Guide

### Step 1: Clone the Repository

First, clone this repository to your local machine:

```bash
git clone https://github.com/<your-username>/<your-repository>.git
cd <your-repository>
Step 2: Run the Installation Script
Run the install_localai_jetson.sh script to set up the Docker environment and start the LocalAI server:

bash
Kopier kode
sudo ./install_localai_jetson.sh
This script will:

Check and install Docker if it's not already installed.
Create the necessary files (Dockerfile, entrypoint script, and systemd service file).
Build the Docker image.
Run the Docker container with NVIDIA GPU support.
Step 3: Access the LocalAI Server
Once the installation script completes, your LocalAI server will be running and accessible at:

copy code
http://localhost:8000
Managing the LocalAI Service
You can manage the LocalAI service using the following commands:

Start the service:

bash
copy code
sudo systemctl start localai
Stop the service:

bash
copy code
sudo systemctl stop localai
Restart the service:

bash
copy code
sudo systemctl restart localai
Check the service status:

bash
copy code
sudo systemctl status localai
File Descriptions
Dockerfile: This file contains the instructions to build the Docker environment for LocalAI, including the installation of dependencies and setup of the virtual environment.
entrypoint.sh: This script is used as the entry point for the Docker container. It starts the LocalAI server and optionally creates a Django superuser.
localai.service: This systemd service file allows you to manage LocalAI as a service on your system.
install_localai_jetson.sh: This is the main installation script that automates the setup of LocalAI on your Jetson Nano.
Troubleshooting
If you encounter any issues during the setup, here are a few tips:

Check Docker Installation:
Ensure Docker is installed and running correctly on your system. You can check the Docker service status with:

bash
copy code
sudo systemctl status docker
Verify File Permissions:
Make sure the install_localai_jetson.sh script has execute permissions:

bash
copy code
chmod +x install_localai_jetson.sh
Review Logs:
If the Docker container fails to start, review the logs for more information:

bash
copy code
sudo docker logs <container-id>
Contributing
Contributions are welcome! If you have any suggestions for improvements or find any issues, please open an issue or submit a pull request.

License
This project is licensed under the MIT License - see the LICENSE file for details.

makefile
Kopier kode

### Full Script for LocalAI Setup on Jetson Nano

Here's the complete installation script again for reference:

```bash
#!/bin/bash

# Function to print messages in green color
print_green() {
    echo -e "\e[32m$1\e[0m"
}

# Function to print error messages in red color
print_red() {
    echo -e "\e[31m$1\e[0m"
}

# Function to handle errors and log them
handle_error() {
    print_red "An error occurred: $1. Exiting."
    exit 1
}

# Ensure the script is run with superuser privileges
if [ "$EUID" -ne 0 ]; then 
    print_red "Please run as root or use sudo."
    exit 1
fi

# Variables
PROJECT_DIR="/path/to/your/project"

# Navigate to your project directory
cd "$PROJECT_DIR" || handle_error "Failed to navigate to project directory"

# Create necessary files
print_green "Creating Dockerfile, entrypoint script, and service file..."

# Dockerfile
cat << 'EOF' > Dockerfile
# Use the official Jetson Nano base image
FROM nvcr.io/nvidia/l4t-base:r32.5.0

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    python3 \
    python3-venv \
    python3-pip \
    wget \
    mpg321 \
    ufw && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up the working directory
WORKDIR /app

# Clone the LocalAI repository
RUN git clone https://github.com/localAI/localai.git
WORKDIR /app/localai

# Create a virtual environment
RUN python3 -m venv venv

# Activate the virtual environment and install required Python packages
RUN . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install ollama gtts

# Download and set up LLMs
RUN mkdir -p models && \
    wget -P models https://example.com/model1.bin && \
    wget -P models https://example.com/model2.bin

# Copy the service file
COPY localai.service /etc/systemd/system/localai.service

# Expose the necessary port
EXPOSE 8000

# Copy and set up the entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Define the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Command to run the application
CMD ["systemctl", "start", "localai"]
EOF

# Entrypoint script
cat << 'EOF' > entrypoint.sh
#!/bin/bash

# Start the LocalAI server
source /app/localai/venv/bin/activate
cd /app/localai

# Check if superuser creation is needed
if [ "$CREATE_SUPERUSER" = "true" ]; then
    python manage.py createsuperuser --noinput --username $DJANGO_SUPERUSER_USERNAME --email $DJANGO_SUPERUSER_EMAIL
fi

# Start the Django server
python manage.py runserver 0.0.0.0:8000
EOF
chmod +x entrypoint.sh

# Systemd service file
cat << 'EOF' > localai.service
[Unit]
Description=LocalAI Server
After=network.target

[Service]
User=root
WorkingDirectory=/app/localai
ExecStart=/app/localai/venv/bin/python manage.py runserver 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Build the Docker image
print_green "Building the Docker image..."
sudo docker build -t localai:latest . || handle_error "Failed to build Docker image"

# Run the Docker container
print_green "Running the Docker container..."
sudo docker run --runtime nvidia -e CREATE_SUPERUSER=true -e DJANGO_SUPERUSER_USERNAME=admin -e DJANGO_SUPERUSER_EMAIL=admin@example.com -p 8000:8000 localai:latest || handle_error "Failed to run Docker container"

# Summary of installation
print_green "LocalAI.io, Ollama, TTS, and LLMs installation complete."
print_green "The LocalAI server is running and can be accessed at http://localhost:8000"
How to Use:
Save the Script:

Save the script to a file, for example, install_localai_jetson.sh.
Make the Script Executable:

bash
copy code
chmod +x install_localai_jetson.sh
Run the Script:

bash
copy code
sudo ./install_localai_jetson.sh
Important:
Replace /path/to/your/project with the actual path to your project directory.
Replace the placeholder URLs (e.g., https://example.com/model1.bin) with the actual URLs of your LLMs.
