const { Kafka } = require('kafkajs');
const fs = require('fs');
const path = require('path');
const os = require('os');

// Load environment variables
require('dotenv').config();

// Kafka consumer configuration
const kafka = new Kafka({
  clientId: process.env.CLIENT_ID || 'latency-test-consumer',
  brokers: process.env.BOOTSTRAP_SERVERS.split(','), // Split brokers from env
});

const consumer = kafka.consumer({
  groupId: process.env.GROUP_ID,
  fetchMinBytes: parseInt(process.env.FETCH_MIN_BYTES, 10) || 1, // Minimum bytes to fetch
});

// Get the EC2 instance name for the consumer
const consumerInstanceName = os.hostname();

// Topic to subscribe to
const topicName = process.env.TOPIC_NAME;

// Log file path
// const logFileName = `${process.env.LOG_FILE.split('.')[0]}_${consumerInstanceName}.log`;
// const logFilePath = path.join(__dirname, logFileName);
const logFilePath = path.join('/logs', `${process.env.LOG_FILE.split('.')[0]}_${consumerInstanceName}.log`);

// Function to write header if the log file is empty
function writeHeaderIfEmpty(filePath) {
  if (!fs.existsSync(filePath) || fs.statSync(filePath).size === 0) {
    fs.writeFileSync(
      filePath,
      'consumer_id,ProducerInstance,ConsumerInstance,UUID,Data,ProducerTimestamp,ConsumerTimestamp,Latency,KPI\n'
    );
  }
}

// Write header to the log file if it's empty
writeHeaderIfEmpty(logFilePath);

// Function to calculate latency
function calculateLatency(producerTimestamp) {
  const consumerTimestamp = new Date();
  const latency = consumerTimestamp - new Date(producerTimestamp); // Latency in ms
  return { latency, consumerTimestamp };
}

// Function to log message details
function logMessage(consumerId, record, producerTimestamp) {
  const { latency, consumerTimestamp } = calculateLatency(producerTimestamp);
  const meetsKpi = latency <= 50; // Check if latency meets the KPI
  const status = meetsKpi ? 'meets KPI' : 'exceeds KPI';

  const logEntry = `${consumerId},${record.producer_instance},${consumerInstanceName},${record.uuid},`
    + `${record.data},${producerTimestamp},${consumerTimestamp.toISOString()},${latency},${status}\n`;

  // Append the log entry to the log file
  fs.appendFileSync(logFilePath, logEntry);
}

// Single-threaded consumer function
async function consumeMessages() {
  const consumerId = `consumer-single-${Date.now()}`;
  console.log(`Single-threaded Consumer ${consumerId} started, subscribing to topic '${topicName}'`);

  await consumer.connect();
  await consumer.subscribe({ topic: topicName, fromBeginning: false });

  await consumer.run({
    eachMessage: async ({ message }) => {
      try {
        const recordValue = message.value.toString();
        const record = JSON.parse(recordValue);

        const producerTimestamp = record.producer_timestamp;

        logMessage(consumerId, record, producerTimestamp);
      } catch (error) {
        console.error(`Error processing message: ${error.message}`);
      }
    },
  });
}

// Start the single-threaded consumer
(async () => {
  console.log(`Starting single-threaded consumer for topic '${topicName}'`);
  await consumeMessages();
})();
