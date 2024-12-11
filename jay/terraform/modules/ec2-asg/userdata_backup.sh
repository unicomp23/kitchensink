#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo dnf update -y

# Install OpenJDK 11
echo "Installing OpenJDK 11..."
sudo dnf install -y  wget java-11-amazon-corretto

# Install python
echo "Installing python..."
sudo dnf install -y python3 python3-pip


# Find the Java installation path
JAVA_HOME_PATH=$(dirname $(dirname $(readlink -f $(which java))))

# Set JAVA_HOME environment variable
echo "Setting JAVA_HOME environment variable..."
echo "export JAVA_HOME=$JAVA_HOME_PATH" >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc

# Define the Kafka version and download URL
KAFKA_VERSION="3.6.0"
SCALA_VERSION="2.13"
KAFKA_DOWNLOAD_URL="https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz"

# Download Kafka binaries
echo "Downloading Kafka $KAFKA_VERSION..."
sudo wget $KAFKA_DOWNLOAD_URL

# Extract the downloaded tar file
echo "Extracting Kafka binaries..."
sudo tar -xzf kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz
sudo rm -rf kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz

# Move to /opt/kafka for easier access
sudo mv kafka_$SCALA_VERSION-$KAFKA_VERSION /opt/kafka

# Add Kafka bin directory to PATH for easy access to client tools
echo 'export PATH=$PATH:/opt/kafka/bin' >> ~/.bashrc

# Apply the changes
source ~/.bashrc

# Verify Java installation
echo "Verifying Java installation..."
java -version

# Confirm JAVA_HOME
echo "JAVA_HOME is set to: $JAVA_HOME"

echo "Java setup is complete. You can now use Kafka tools or any Java-based applications."

# Verify the Kafka tools installation
echo "Verifying Kafka installation..."
kafka-topics.sh --version

echo "Kafka Client Tools are set up successfully!"
echo "Use 'kafka-topics.sh', 'kafka-console-producer.sh', and 'kafka-console-consumer.sh' to manage Kafka topics and messages."