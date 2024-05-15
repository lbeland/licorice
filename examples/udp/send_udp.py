import socket
import sys
import time

import numpy as np

IP = sys.argv[1].split(":")[0]
PORT = int(sys.argv[1].split(":")[1])

DATA_CHANNELS = 120
DATA_LEN = 100
# DATA_RATE

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# data = "Test string"
# encoded_data = data.encode('utf-8')

data = np.ones((DATA_CHANNELS, DATA_LEN), dtype=np.int8)
encoded_data = data.tobytes()

pkt_count = 0
start_time = time.time()
while pkt_count < 1000:
    sock.sendto(encoded_data, (IP, PORT))
    pkt_count += 1

end_time = time.time()

send_time = end_time - start_time
print(f"{pkt_count} packets sent in {send_time:.1f} s.")
print(
    f"Data rate: {1.e-6 * len(encoded_data) * pkt_count / send_time:.1f} mB/s"
)
