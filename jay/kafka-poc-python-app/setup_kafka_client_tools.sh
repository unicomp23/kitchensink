#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define the Kafka version and download URL
KAFKA_VERSION="3.6.0"
SCALA_VERSION="2.13"
KAFKA_DOWNLOAD_URL="https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz"

# Download Kafka binaries
echo "Downloading Kafka $KAFKA_VERSION..."
wget $KAFKA_DOWNLOAD_URL

# Extract the downloaded tar file
echo "Extracting Kafka binaries..."
tar -xzf kafka_2.13-3.6.0.tgz
rm kafka_2.13-3.6.0.tgz

# Move to /opt/kafka for easier access
sudo mv kafka_2.13-3.6.0 /opt/kafka

# Add Kafka bin directory to PATH for easy access to client tools
echo 'export PATH=$PATH:/opt/kafka/bin' >> ~/.bashrc
source ~/.bashrc

# Verify the Kafka tools installation
echo "Verifying Kafka installation..."
kafka-topics.sh --version

echo "Kafka Client Tools are set up successfully!"
echo "Use 'kafka-topics.sh', 'kafka-console-producer.sh', and 'kafka-console-consumer.sh' to manage Kafka topics and messages.