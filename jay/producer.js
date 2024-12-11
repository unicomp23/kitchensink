const { Kafka } = require('kafkajs');
const { v4: uuidv4 } = require('uuid'); // To generate unique IDs
const os = require('os'); // To get the hostname of the EC2 instance
require('dotenv').config(); // Load environment variables from .env

// Kafka configuration loaded from .env file
const kafka = new Kafka({
  brokers: process.env.BOOTSTRAP_SERVERS.split(','),
  clientId: 'kafka-producer',
});

// Initialize Kafka producer
const producer = kafka.producer();

// Get the EC2 instance name
const producerInstanceName = os.hostname();

// Function to produce messages at a fixed rate (2 messages per second)
const produceMessagesAtFixedRate = async (numMessages, messagesPerSecond) => {
  const intervalMs = 1000 / messagesPerSecond; // Time interval in milliseconds for the desired rate
  try {
    await producer.connect(); // Connect the producer
    console.log(`Producer connected. EC2 Instance: ${producerInstanceName}`);

    for (let i = 0; i < numMessages; i++) {
      const message = {
        uuid: uuidv4(),
        data: `sample_data_message_${i}`,
        producer_instance: producerInstanceName,
        producer_timestamp: new Date().toISOString(),
      };

      // Send the message to Kafka
      await producer.send({
        topic: process.env.TOPIC_NAME,
        messages: [
          {
            key: message.uuid,
            value: JSON.stringify(message),
          },
        ],
      });

      console.log(`Message ${i + 1}/${numMessages} sent:`, message);

      // Wait only if not the last message
      if (i < numMessages - 1) {
        await new Promise((resolve) => setTimeout(resolve, intervalMs));
      }
    }

    console.log('All messages sent.');
  } catch (error) {
    console.error('Error in producer:', error);
  } finally {
    await producer.disconnect(); // Disconnect the producer
    console.log('Producer disconnected.');
  }
};

// Main function to execute the producer
const startProducer = async () => {
  const numMessages = parseInt(process.env.NUM_MESSAGES, 10);
  const messagesPerSecond = 2; // Fixed rate of 2 messages per second

  await produceMessagesAtFixedRate(numMessages, messagesPerSecond);
};

// Start the producer
startProducer();

