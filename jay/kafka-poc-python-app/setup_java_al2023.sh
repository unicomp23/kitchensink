#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo dnf update -y

# Install OpenJDK 11
echo "Installing OpenJDK 11..."
sudo dnf install -y java-11-amazon-corretto

# Find the Java installation path
JAVA_HOME_PATH=$(dirname $(dirname $(readlink -f $(which java))))

# Set JAVA_HOME environment variable
echo "Setting JAVA_HOME environment variable..."
echo "export JAVA_HOME=$JAVA_HOME_PATH" >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc

# Apply the changes
source ~/.bashrc

# Verify Java installation
echo "Verifying Java installation..."
java -version

# Confirm JAVA_HOME
echo "JAVA_HOME is set to: $JAVA_HOME"

echo "Java setup is complete. You can now use Kafka tools or any Java-based applications."
