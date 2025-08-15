import struct

if udp_dataBufVars[9] - udp_dataBufVars[8] > 0:
    # parse UDP packet data
    data_arr = udp_dataRaw[udp_dataBufVars[8]: udp_dataBufVars[9]]
    # decode unpacked data
    unpacked_int = struct.unpack("Q", data_arr[0])[0]
    print(unpacked_int, flush=True)

