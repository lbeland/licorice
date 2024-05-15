import struct

if udp_dataBufVars[9] - udp_dataBufVars[8] > 0:
    #Remove the data in the UDP packet that is nice to play to with 
    data_arr = udp_dataRaw[udp_dataBufVars[8] : udp_dataBufVars[9]]
    #Using this data we can now decode it back from the bytes that we were sending over 
    unpacked_int = struct.unpack("Q", data_arr[0])[0]
    print(unpacked_int, flush=True)

