import pandas as pd

# Path to the log file
log_file_path = "consumer_nodejs_log_b1e50a860f4f.csv"  # Update with your actual log file path

# Load the log file into a Pandas DataFrame
try:
    data = pd.read_csv(log_file_path, header=None)
except FileNotFoundError:
    print(f"Error: File not found at {log_file_path}")
    exit(1)

# Define headers explicitly to match the structure of the log file
data.columns = [
    "ConsumerID",
    "ProducerInstance",
    "ConsumerInstance",
    "UUID",
    "Data",
    "ProducerTimestamp",
    "ConsumerTimestamp",
    "Latency",
    "KPI",
]

# Convert Latency column to numeric, handling any invalid data
data["Latency"] = pd.to_numeric(data["Latency"], errors="coerce")

# 1. Total messages
message_count = len(data)

# 2. Average latency
average_latency = data["Latency"].mean()

# 3. Median latency
median_latency = data["Latency"].median()

# 4. Messages meeting KPI
kpi_met_count = data[data["KPI"] == "meets KPI"].shape[0]

# 5. Messages not meeting KPI
kpi_not_met_count = message_count - kpi_met_count

# 6. Top 5 messages with highest latency
top_5_latency = data.nlargest(5, "Latency")[["UUID", "Latency", "KPI"]]

# Output results
print("\nAnalytics Results:")
print(f"Total Messages: {message_count}")
print(f"Average Latency: {average_latency:.4f} ms")
print(f"Median Latency: {median_latency:.4f} ms")
print(f"Messages Meeting KPI: {kpi_met_count}")
print(f"Messages Not Meeting KPI: {kpi_not_met_count}")

print("\nTop 5 Messages with Highest Latency:")
print(top_5_latency.to_string(index=False))

