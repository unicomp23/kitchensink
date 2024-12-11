from confluent_kafka import Producer
import threading
import time
import uuid
import json
import socket  # To get the hostname of the EC2 instance
from datetime import datetime
from dotenv import load_dotenv  # Import dotenv to load environment variables
import os

# Load environment variables from .env file
load_dotenv()

# Kafka producer configuration
conf = {
    'bootstrap.servers': os.getenv('BOOTSTRAP_SERVERS'),
    'linger.ms': int(os.getenv('LINGER_MS')),
    'batch.size': int(os.getenv('BATCH_SIZE')),
    'compression.type': os.getenv('COMPRESSION_TYPE'),
    'acks': os.getenv('ACKS'),
}

# Initialize Kafka producer
producer = Producer(conf)

# Get the EC2 instance name
producer_instance_name = socket.gethostname()

# Producer function that runs in each thread
def produce_messages(thread_id, num_messages, message_interval):
    for _ in range(num_messages):
        message = {
            "uuid": str(uuid.uuid4()),
            "data": f"sample_data_from_thread_{thread_id}",
            "producer_instance": producer_instance_name,
            "producer_timestamp": datetime.utcnow().isoformat()
        }
        # Convert message to JSON string
        producer.produce(os.getenv('TOPIC_NAME'), key=message["uuid"], value=json.dumps(message))
        # Call poll to handle delivery callbacks
        producer.poll(0)
        time.sleep(message_interval)  # Control message rate

# Function to periodically call poll to clear out the queue
def poll_producer():
    while True:
        producer.poll(float(os.getenv('POLL_INTERVAL')))  # Processes any delivery callbacks in the background

# Start the poll thread
poll_thread = threading.Thread(target=poll_producer, daemon=True)
poll_thread.start()

# Number of threads, messages per thread, and message interval
num_threads = int(os.getenv('NUM_THREADS'))
num_messages = int(os.getenv('NUM_MESSAGES'))
message_interval = float(os.getenv('MESSAGE_INTERVAL'))

# Start producer threads
threads = []
for i in range(num_threads):
    thread = threading.Thread(target=produce_messages, args=(i, num_messages, message_interval))
    threads.append(thread)
    thread.start()

# Wait for all threads to finish
for thread in threads:
    thread.join()

# Flush any remaining messages
producer.flush()
