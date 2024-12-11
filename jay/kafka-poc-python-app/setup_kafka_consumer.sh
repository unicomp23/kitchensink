#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if Python3 is installed
if ! command -v python3 &> /dev/null
then
    echo "Python3 is not installed. Installing Python3..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip
else
    echo "Python3 is already installed."
fi

# Create a virtual environment (optional but recommended)
echo "Creating a virtual environment..."
python3 -m venv kafka_consumer_env

# Activate the virtual environment
source kafka_consumer_env/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install required Python packages
echo "Installing required packages..."
pip install confluent-kafka

# Install required Python packages
echo "Installing required packages..."
pip install pandas

echo "Installation complete. To use the virtual environment, run: source kafka_consumer_env/bin/activate"

# Sample usage reminder
echo "You can now run your Kafka consumer code using the confluent-kafka library."