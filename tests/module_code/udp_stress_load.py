if udp_dataBufVars[9] - udp_dataBufVars[8] > 0:
    data_arr = udp_dataRaw[udp_dataBufVars[8] : udp_dataBufVars[9]]
    num_messages = data_arr.shape[0]
    
    for i in range(num_messages):
        message = ''
        for c in data_arr[i]:
            
            char = chr(c)
            if char == '#':
                break
            message += char
    
        print(message, flush = True)