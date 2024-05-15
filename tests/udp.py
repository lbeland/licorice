import re
import socket


def udp_server_recv(port, timeout=60.0):
    family_addr = socket.AF_INET
    sock = socket.socket(family_addr, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.settimeout(timeout)
    data = None

    try:
        # where it opens the socket
        # we are now bound to this port and we are writing to this port
        sock.bind(("", port))
    except socket.error as e:
        print("Bind failed:{}".format(e))
        sock.close()
        raise

    try:
        # recieve from the port
        # how many bites you wanna read
        data, addr = sock.recvfrom(1024)
        print(addr)
        if not data:
            sock.close()
            return
        data = data.decode()
        print("Reply[" + addr[0] + ":" + str(addr[1]) + "] - " + data)
        reply = "OK"
        # specifies the data you want to send and the target ip addresss
        # call send to repeatedly
        # send the local host as some arbitrary buffer that
        # licorice has to read and parse.
        sock.sendto(reply.encode(), addr)
    except socket.error as e:
        print("Running server failed:{}".format(e))
        sock.close()
        raise

    sock.close()

    regex = re.compile(
        r"Mean: (\d*[.]\d*), StdDev: (\d*[.]\d*), "
        r"Min: (\d*[.]\d*), Max: (\d*[.]\d*)"
    )
    m = regex.search(data)
    return [float(x) for x in m.groups()]
