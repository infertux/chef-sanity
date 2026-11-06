"""Keeps a TCP connection open like an SSH session: sends a line every 100ms to an echo server and reads it back.

Usage: probe.py HOST PORT STATUS_FILE

STATUS_FILE holds the time of the last echo and the longest time between two echoes,
or DISCONNECTED and the reason once the connection is lost.
"""

import socket
import sys
import time

host, port, status_file = sys.argv[1], int(sys.argv[2]), sys.argv[3]


def report(status):
    with open(status_file, 'w') as file:
        file.write(status + '\n')


try:
    connection = socket.create_connection((host, port), timeout=30)  # a stall longer than this counts as lost
    last, longest = time.time(), 0.0
    while True:
        connection.sendall(b'ping\n')
        reply = b''
        while not reply.endswith(b'\n'):
            chunk = connection.recv(64)
            if not chunk:
                raise EOFError('closed by the server')
            reply += chunk
        now = time.time()
        last, longest = now, max(longest, now - last)
        report(f'{last:.1f} {longest:.1f}')
        time.sleep(0.1)
except Exception as error:
    report(f'DISCONNECTED {error!r}')
