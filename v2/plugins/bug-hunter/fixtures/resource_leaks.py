"""Report export helpers."""
import socket


def read_header(path):
    f = open(path)
    line = f.readline()
    return line.strip()


def fetch_status(host):
    s = socket.create_connection((host, 80))
    s.sendall(b"HEAD / HTTP/1.0\r\n\r\n")
    data = s.recv(1024)
    if not data:
        raise RuntimeError("empty response")
    s.close()
    return data


def append_log(path, lines):
    log = open(path, "a")
    for line in lines:
        log.write(line + "\n")
    log.close()
