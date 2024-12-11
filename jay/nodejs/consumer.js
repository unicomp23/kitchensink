const { Kafka } = require("kafkajs");
const fs = require("fs");
const os = require("os");
const path = require("path");
require("dotenv").config(); // Load environment variables

// Constants and configurations
const brokers = process.env.BROKERS.split(",");
const topicName = process.env.TOPIC_NAME;
const groupId = process.env.GROUP_ID;
const logDir = "/logs";
const logFileTemplate = `consumer_nodejs_log_${os.hostname()}.csv`;
const kpiThreshold = parseInt(process.env.KPI_THRESHOLD, 10) || 50;

// Ensure log directory exists
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

// Log file path
const logFile = path.join(logDir, logFileTemplate);

// Write CSV header if the file is empty
if (!fs.existsSync(logFile)) {
  fs.writeFileSync(
    logFile,
    "consumer_id,ProducerInstance,ConsumerInstance,UUID,Data,ProducerTimestamp,ConsumerTimestamp,Latency,KPI\n"
  );
}

// Function to log messages to CSV
const logMessage = (consumerId, record, producerTimestamp) => {
  const producerDate = new Date(producerTimestamp);
  const consumerDate = new Date();
  const latency = consumerDate - producerDate; // Latency in milliseconds
  const meetsKpi = latency <= kpiThreshold ? "meets KPI" : "exceeds KPI";

  const logEntry = `${consumerId},${record.producer_instance},${os.hostname()},${record.uuid},${record.data},${producerTimestamp},${consumerDate.toISOString()},${latency},${meetsKpi}\n`;
  fs.appendFileSync(logFile, logEntry);
};

// Kafka Consumer setup
const kafka = new Kafka({ clientId: os.hostname(), brokers });
const consumer = kafka.consumer({ groupId });

// Message consumption logic
const consumeMessages = async () => {
  await consumer.connect();
  console.log(`Consumer connected, subscribing to topic '${topicName}'`);
  await consumer.subscribe({ topic: topicName, fromBeginning: false });

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      try {
        const recordValue = message.value ? message.value.toString() : null;
        if (recordValue) {
          const record = JSON.parse(recordValue); // Assuming the message is JSON
          const producerTimestamp = record.producer_timestamp;

          if (producerTimestamp) {
            logMessage("consumer_id", record, producerTimestamp);
          } else {
            console.error("Invalid message: Missing producer_timestamp");
          }
        } else {
          console.error("Invalid message: Null value received");
        }
      } catch (err) {
        console.error("Error processing message:", err); // Log the error but keep running
      }
    },
  });
};

consumeMessages()
  .catch((err) => {
    console.error("Error in consumer:", err);
  });

