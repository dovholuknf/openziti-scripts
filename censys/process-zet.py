from collections import defaultdict

# Dictionary to store min and max dates for each IP and path
ip_data = defaultdict(lambda: defaultdict(lambda: {'min': '9999-99-99', 'max': '0000-00-00', 'count': 0}))

# Read data from the file
with open('all-ubuntu-data-stable-by-ip-and-date.txt', 'r') as file:
    for line in file:
        # Split the line into columns
        columns = line.strip().split('\t')
        
        # Extract relevant information
        ip = columns[0]
        date = columns[1]
        path = columns[2]
        
        # Update min and max dates for the specific IP and path
        ip_data[ip][path]['min'] = min(ip_data[ip][path]['min'], date)
        ip_data[ip][path]['max'] = max(ip_data[ip][path]['max'], date)
        
        # Increment the counter
        ip_data[ip][path]['count'] += 1

# Print the result
for ip, path_data in ip_data.items():
    for path, data in path_data.items():
        if data['min'] != data['max']:
            print(f"{ip}\t{data['min']}\t{data['max']}\t{data['count']}\t{path}")
