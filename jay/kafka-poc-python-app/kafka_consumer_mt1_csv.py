from confluent_kafka import Consumer, KafkaError
import json
import threading
import uuid
from datetime import datetime
import os
import logging

# Kafka consumer configuration optimized for low latency
kafka_config = {
    'bootstrap.servers': 'b-1.kafkapoccluster.7pxrbv.c20.kafka.us-east-1.amazonaws.com:9092,b-2.kafkapoccluster.7pxrbv.c20.kafka.us-east-1.amazonaws.com:9092,b-3.kafkapoccluster.7pxrbv.c20.kafka.us-east-1.amazonaws.com:9092',
    'group.id': 'latency_test_consumer_group',      # Consumer group ID
    'auto.offset.reset': 'latest',                  # Start reading from the latest messages
    'fetch.min.bytes': 1,                           # Fetch messages as soon as they arrive
    #'fetch.max.bytes': 1048576,                     # 1 MB max fetch size to allow large batches if available
    #'fetch.wait.max.ms': 10,                        # Low wait time to minimize delay for messages to be ready
    'enable.auto.commit': False                    # Disable auto commit for precise control
    #'max.poll.interval.ms': 1000,                   # Poll frequently to keep consumer active
}

# Topic to subscribe to
topic_name = 'kafka-poc-group10-producer-1mps'

# Log file path
log_file = 'consumer_1mps.log'

# Function to write header if file is empty
def write_header_if_empty(file_path):
    if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
        with open(file_path, 'w') as f:
            header = "consumer_id,UUID,Data,ProducerTimestamp,ConsumerTimestamp,Latency,KPI"
            f.write(header + '\n')

# Configure logging
logging.basicConfig(
    filename=log_file,
    filemode='a',
    format='%(message)s',
    level=logging.INFO
)

# Write the header if the file is empty
write_header_if_empty(log_file)

# Function to calculate latency between producer and consumer
def calculate_latency(producer_timestamp):
    consumer_timestamp = datetime.utcnow()
    latency = (consumer_timestamp - producer_timestamp).total_seconds() * 1000  # Latency in ms
    return latency, consumer_timestamp

# Consumer function to be run by each thread
def consume_messages(consumer_id):
    consumer = Consumer(kafka_config)
    consumer.subscribe([topic_name])

    print(f"Consumer {consumer_id} started, subscribing to topic '{topic_name}'")

    try:
        while True:
            # Poll for new messages
            msg = consumer.poll(timeout=1.0)
            
            if msg is None:
                continue  # No new message, try again

            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    print(f"End of partition reached {msg.topic()} [{msg.partition()}]")
                else:
                    print(f"Consumer {consumer_id} error: {msg.error()}")
                continue

            # Decode the message and parse JSON
            record_value = msg.value().decode('utf-8')
            record = json.loads(record_value)

            # Extract producer timestamp and calculate latency
            producer_timestamp = datetime.fromisoformat(record['producer_timestamp'])
            latency, consumer_timestamp = calculate_latency(producer_timestamp)

            # Determine if the latency meets the KPI threshold of 100 ms
            meets_kpi = latency <= 50
            status = "meets KPI" if meets_kpi else "exceeds KPI"

            # Log the result in CSV format
            logging.info(
                f"{consumer_id},{record['uuid']},{record['data']},"
                f"{producer_timestamp},{consumer_timestamp},"
                f"{latency:.4f},{status}"
            )

            # Commit offsets manually after processing each message
            consumer.commit(asynchronous=True)

    except KeyboardInterrupt:
        print(f"Consumer {consumer_id} interrupted.")
    finally:
        consumer.close()
        print(f"Consumer {consumer_id} has stopped.")

# Main function to start multiple consumer threads
def start_consumers(num_consumers):
    threads = []

    for i in range(num_consumers):
        consumer_id = str(uuid.uuid4())  # Unique ID for each consumer
        thread = threading.Thread(target=consume_messages, args=(consumer_id,))
        threads.append(thread)
        thread.start()
        print(f"Started consumer thread {consumer_id}")

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

if __name__ == "__main__":
    num_consumer_threads = 20  # Number of consumer threads you want to run

    print(f"Starting {num_consumer_threads} consumers for topic '{topic_name}'")
    start_consumers(num_consumer_threads)
