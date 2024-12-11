from confluent_kafka import Producer
import threading
import time
import uuid
import json
import socket  # To get the hostname of the EC2 instance
from datetime import datetime

# Kafka producer configuration
conf = {
    'bootstrap.servers': 'b-3.kafkapoccluster.7pxrbv.c20.kafka.us-east-1.amazonaws.com:9092,b-2.kafkapoccluster.7pxrbv.c20.kafka.us-east-1.amazonaws.com:9092,b-1.kafkapoccluster.7pxrbv.c20.kafka.us-east-1.amazonaws.com:9092',
    'linger.ms': 5,
    'batch.size': 65536,
    'compression.type': 'lz4',
    'acks': '1',
}

# Initialize Kafka producer
producer = Producer(conf)

# Get the EC2 instance name
producer_instance_name = socket.gethostname()

# Producer function that runs in each thread
def produce_messages(thread_id, num_messages):
    for _ in range(num_messages):
        message = {
            "uuid": str(uuid.uuid4()),
            "data": f"sample_data_from_thread_{thread_id}",
            "producer_instance": producer_instance_name,
            "producer_timestamp": datetime.utcnow().isoformat()
        }
        # Convert message to JSON string
        producer.produce("kafka-poc-group10-producer-1mps_v2", key=message["uuid"], value=json.dumps(message))
        # Call poll to handle delivery callbacks
        producer.poll(0)
        time.sleep(1)  # Control message rate (1 message per second)

# Function to periodically call poll to clear out the queue
def poll_producer():
    while True:
        producer.poll(1)  # Processes any delivery callbacks in the background

# Start the poll thread
poll_thread = threading.Thread(target=poll_producer, daemon=True)
poll_thread.start()

# Number of threads and messages per thread
num_threads = 100
num_messages = 7200  # Messages per thread

# Start producer threads
threads = []
for i in range(num_threads):
    thread = threading.Thread(target=produce_messages, args=(i, num_messages))
    threads.append(thread)
    thread.start()

# Wait for all threads to finish
for thread in threads:
    thread.join()

# Flush any remaining messages
producer.flush()
