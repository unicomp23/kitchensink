# Base image
FROM node:18

# Set working directory
WORKDIR /app

# Copy application files
COPY package.json package-lock.json ./
COPY producer.js consumer.js ./

# Install dependencies
RUN npm install

# Set the default environment variable to determine which script to run
ENV SCRIPT_TYPE=producer

# Command to run the specified script
CMD ["sh", "-c", "node $SCRIPT_TYPE.js"]

