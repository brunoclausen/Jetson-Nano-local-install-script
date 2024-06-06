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
