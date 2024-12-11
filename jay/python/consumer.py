import json
import threading
import uuid
from datetime import datetime
import os
import socket
import logging
from confluent_kafka import Consumer, KafkaError
from dotenv import load_dotenv  # Import dotenv to load environment variables

# Load environment variables from .env file
load_dotenv()

# Kafka consumer configuration optimized for low latency
kafka_config = {
    'bootstrap.servers': os.getenv('BOOTSTRAP_SERVERS'),
    'group.id': os.getenv('GROUP_ID'),
    'auto.offset.reset': 'latest',
    'fetch.min.bytes': int(os.getenv('FETCH_MIN_BYTES')),
    'enable.auto.commit': False
}

# Get the EC2 instance name for the consumer
consumer_instance_name = socket.gethostname()

# Topic to subscribe to
topic_name = os.getenv('TOPIC_NAME')

# Log file path
# Gets the directory where your script is located
script_dir = os.path.dirname(os.path.abspath(__file__))
hostname = socket.gethostname()
log_file = os.path.join(script_dir, f"{os.getenv('LOG_FILE').rsplit('.', 1)[0]}_{hostname}.log")
# log_file = os.path.join(script_dir, os.getenv('LOG_FILE'))

# Function to write header if file is empty
def write_header_if_empty(file_path):
    if not os.path.exists(file_path) or os.path.getsize(file_path) == 0:
        with open(file_path, 'w') as f:
            header = "consumer_id,ProducerInstance,ConsumerInstance,UUID,Data,ProducerTimestamp,ConsumerTimestamp,Latency,KPI"
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

            # Determine if the latency meets the KPI threshold of 50 ms
            meets_kpi = latency <= 50
            status = "meets KPI" if meets_kpi else "exceeds KPI"

            # Log the result in CSV format
            logging.info(
                f"{consumer_id},{record['producer_instance']},{consumer_instance_name},{record['uuid']},"
                f"{record['data']},{producer_timestamp},{consumer_timestamp},{latency:.4f},{status}"
            )

            # Commit offsets manually after processing each message
            consumer.commit(asynchronous=True)

    except KeyboardInterrupt:
        print(f"Consumer {consumer_id} interrupted.")
    finally:
        consumer.close()
        print(f"Consumer {consumer_id} has stopped.")

# Main function to start multiple consumer threads
def start_consumers(num_consumer_threads):
    threads = []

    for i in range(num_consumer_threads):
        consumer_id = str(uuid.uuid4())  # Unique ID for each consumer
        thread = threading.Thread(target=consume_messages, args=(consumer_id,))
        threads.append(thread)
        thread.start()
        print(f"Started consumer thread {consumer_id}")

    # Wait for all threads to complete
    for thread in threads:
        thread.join()

if __name__ == "__main__":
    num_consumer_threads = int(os.getenv('NUM_CONSUMER_THREADS'))  # Number of consumer threads to run

    print(f"Starting {num_consumer_threads} consumers for topic '{topic_name}'")
    start_consumers(num_consumer_threads)
