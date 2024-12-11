const { Kafka, logLevel } = require('kafkajs');
const { v4: uuidv4 } = require('uuid');
const yargs = require('yargs');
const { hideBin } = require('yargs/helpers');
const { writeFileSync, appendFileSync, unlinkSync, existsSync } = require('fs');

// Utility to get the hostname for producer and consumer instances
const producerInstanceName = os.hostname();
const consumerInstanceName = os.hostname();

const getKafkaClient = async () => {
  const brokers = process.env.KAFKA_BROKERS
    ? process.env.KAFKA_BROKERS.split(',').map(broker => broker.trim())
    : ['localhost:9092'];

  const kafka = new Kafka({
    clientId: 'latency-test',
    brokers,
    ssl: false,
    sasl: undefined,
    connectionTimeout: 3000,
    retry: {
      initialRetryTime: 100,
      retries: 3,
    },
  });

  return kafka;
};

// Message structure
interface Message {
  uuid: string;
  data: string;
  producer_instance: string;
  producer_timestamp: string;
}

async function publish(topic: string, iterations: number, sleepMs: number) {
  const kafka = await getKafkaClient();
  const producer = kafka.producer();

  await producer.connect();

  console.log(
    JSON.stringify({
      event: 'publish_start',
      iterations,
      topic,
      producerInstanceName,
    })
  );

  for (let i = 0; i < iterations; i++) {
    const message: Message = {
      uuid: uuidv4(),
      data: `sample_data_from_thread_${i}`,
      producer_instance: producerInstanceName,
      producer_timestamp: new Date().toISOString(),
    };

    await producer.send({
      topic,
      acks: 1,
      messages: [{ key: message.uuid, value: JSON.stringify(message) }],
    });

    console.log(
      JSON.stringify({
        event: 'message_published',
        iteration: i + 1,
        totalMessages: iterations,
        uuid: message.uuid,
        producerInstance: producerInstanceName,
      })
    );

    if (sleepMs > 0) {
      await new Promise(resolve => setTimeout(resolve, sleepMs));
    }
  }

  await producer.disconnect();
  console.log(JSON.stringify({ event: 'publish_complete', topic }));
}

async function consume(topic: string, durationSec: number, groupId?: string) {
  const logFile = `/tmp/consumer_${consumerInstanceName}.log`;
  if (existsSync(logFile)) unlinkSync(logFile);

  const kafka = await getKafkaClient();
  const consumer = kafka.consumer({ groupId: groupId || 'latency-group' });

  await consumer.connect();
  await consumer.subscribe({ topic, fromBeginning: false });

  console.log(
    JSON.stringify({
      event: 'consumer_subscribed',
      topic,
      consumerInstanceName,
    })
  );

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      const receivedTime = new Date();
      const record = JSON.parse(message.value?.toString() || '{}');
      const producerTimestamp = new Date(record.producer_timestamp);
      const latency = receivedTime.getTime() - producerTimestamp.getTime();
      const status = latency <= 50 ? 'meets KPI' : 'exceeds KPI';

      const logLine = `${uuidv4()},${record.producer_instance},${consumerInstanceName},${record.uuid},`
        + `${record.data},${producerTimestamp.toISOString()},${receivedTime.toISOString()},${latency},${status}\n`;

      appendFileSync(logFile, logLine);

      console.log(
        JSON.stringify({
          event: 'message_processed',
          uuid: record.uuid,
          latency,
          producerInstance: record.producer_instance,
          consumerInstance: consumerInstanceName,
        })
      );
    },
  });

  // Run the consumer for the specified duration
  await new Promise(resolve => setTimeout(resolve, durationSec * 1000));
  await consumer.disconnect();
  console.log(JSON.stringify({ event: 'consume_complete', topic }));
}

async function main() {
  const argv = await yargs(hideBin(process.argv))
    .usage('Usage: $0 --mode <mode> [options]')
    .option('mode', {
      alias: 'm',
      choices: ['publish', 'consume'] as const,
      demandOption: true,
      description: 'Operation mode',
    })
    .option('iterations', {
      alias: 'i',
      type: 'number',
      description: 'Number of messages to publish (publish mode only)',
      default: 10,
    })
    .option('duration', {
      alias: 'd',
      type: 'number',
      description: 'Duration to consume messages in seconds (consume mode only)',
      default: 30,
    })
    .option('topic', {
      alias: 't',
      type: 'string',
      description: 'Kafka topic',
      default: 'latency-test',
    })
    .option('sleep', {
      type: 'number',
      description: 'Sleep duration between publishes in milliseconds',
      default: 0,
    })
    .option('groupId', {
      type: 'string',
      description: 'Consumer group ID (consume mode only)',
      default: 'latency-group',
    })
    .help()
    .alias('help', 'h')
    .version()
    .alias('version', 'v')
    .argv;

  if (argv.mode === 'publish') {
    await publish(argv.topic, argv.iterations, argv.sleep);
  } else if (argv.mode === 'consume') {
    await consume(argv.topic, argv.duration, argv.groupId);
  }
}

main().catch(console.error);
