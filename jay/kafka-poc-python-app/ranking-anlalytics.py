import pandas as pd

# Load the data
log_file_path = "consumer_1mps.csv"  # Path to your log file
data = pd.read_csv(log_file_path)

# Define bins and labels
max_latency = int(data['Latency'].max())  # Convert max latency to integer
bins = list(range(0, max_latency + 10, 10))  # Bins from 0 to the max latency value in steps of 10
labels = [f"{i}-{i+9}" for i in range(0, max_latency, 10)]

# Create a new column with the latency range
data['Latency_Range'] = pd.cut(data['Latency'], bins=bins, labels=labels, right=False)

# Count rows in each latency range
latency_counts = data['Latency_Range'].value_counts().sort_index()

# Display the counts
print("Count of rows in each latency range:")
print(latency_counts)