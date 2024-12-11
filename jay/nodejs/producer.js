const { Kafka } = require("kafkajs");
const os = require("os");
require("dotenv").config(); // Load environment variables

// Kafka setup
const kafka = new Kafka({
  clientId: os.hostname(),
  brokers: process.env.BROKERS.split(","), // Brokers from .env
});

// Configuration from .env with debug logs
console.log("Loading configuration from .env...");
const topicName = process.env.TOPIC_NAME || "default-topic";
const numThreads = parseInt(process.env.NUM_THREADS, 10) || 1;
const numMessages = parseInt(process.env.NUM_MESSAGES, 10) || 100;
const kpiThreshold = parseInt(process.env.KPI_THRESHOLD, 10) || 50;
const messageInterval = parseInt(process.env.MESSAGE_INTERVAL, 10) * 1000 || 1000;

console.log("Configuration:");
console.log(`  Topic Name: ${topicName}`);
console.log(`  Number of Threads: ${numThreads}`);
console.log(`  Messages per Thread: ${numMessages}`);
console.log(`  Message Interval: ${messageInterval}ms`);

const producer = kafka.producer();

// Helper function for delay
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Message production logic
const produceMessages = async () => {
  await producer.connect();
  console.log("Producer connected");

  for (let threadId = 0; threadId < numThreads; threadId++) {
    console.log(`Starting thread ${threadId}`);
    for (let i = 0; i < numMessages; i++) {
      const producerTimestamp = new Date().toISOString();

      const message = {
        uuid: `${threadId}-${i}-${Date.now()}`,
        data: `sample_data_from_thread_${threadId}_${i}`,
        producer_instance: os.hostname(),
        producer_timestamp: producerTimestamp,
      };

      // Send message to Kafka
      await producer.send({
        topic: topicName,
        messages: [
          {
            key: message.uuid,
            value: JSON.stringify(message),
          },
        ],
      });

      // Debug log after sending each message
      console.log(`Thread ${threadId}: Sent message ${message.uuid} at ${producerTimestamp}`);

      // Simulate latency calculation and KPI check
      const consumerTimestamp = new Date(); // Assume instant processing for simulation
      const latency = new Date(consumerTimestamp) - new Date(producerTimestamp);

      const meetsKpi = latency <= kpiThreshold;

      // Show result in terminal
      if (meetsKpi) {
        console.log(`✅ Message ${message.uuid} meets KPI: Latency = ${latency}ms`);
      } else {
        console.log(`❌ Message ${message.uuid} exceeds KPI: Latency = ${latency}ms`);
      }

      // Debug log before sleeping
      console.log(`Thread ${threadId}: Sleeping for ${messageInterval}ms before next message`);
      await sleep(messageInterval);
    }
    console.log(`Thread ${threadId} finished`);
  }

  await producer.disconnect();
  console.log("Producer finished");
};

// Run the producer
produceMessages().catch((err) => {
  console.error("Error in producer:", err);
});

