# Base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy application files
COPY requirements.txt ./
COPY producer.py consumer.py ./
COPY .env ./

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Set the default environment variable to determine which script to run
ENV SCRIPT_TYPE=producer

# Command to run the specified script
CMD ["sh", "-c", "python $SCRIPT_TYPE.py"]

