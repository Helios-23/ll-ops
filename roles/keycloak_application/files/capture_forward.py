#!/usr/bin/env python3
"""Forward private Docker-network capture SMTP only into loopback SSH tunnels."""
import ipaddress
import json
from pathlib import Path
import selectors
import socket
import socketserver
import threading


class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        try:
            with socket.create_connection(('127.0.0.1', self.server.target), timeout=10) as upstream:
                self.request.settimeout(10)
                with selectors.DefaultSelector() as selector:
                    selector.register(self.request, selectors.EVENT_READ, upstream)
                    selector.register(upstream, selectors.EVENT_READ, self.request)
                    total = 0
                    while total <= 512 * 1024:
                        ready = selector.select(timeout=20)
                        if not ready:
                            return
                        for key, _ in ready:
                            data = key.fileobj.recv(16384)
                            if not data:
                                return
                            total += len(data)
                            key.data.sendall(data)
        except OSError:
            pass


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

    def verify_request(self, request, client_address):
        return ipaddress.ip_address(client_address[0]) in self.allowed and self.slots.acquire(blocking=False)

    def process_request_thread(self, request, client_address):
        try:
            super().process_request_thread(request, client_address)
        finally:
            self.slots.release()


def main():
    config = json.loads(Path('/etc/keycloak-capture-forward.json').read_text())
    gateway = ipaddress.ip_address(config['gateway'])
    network = ipaddress.ip_network(config['subnet'])
    if not gateway.is_private or gateway.is_loopback or gateway not in network:
        raise SystemExit('Private Docker gateway required')
    servers = []
    for listen, target in [(21126, 21125), (21226, 21225)]:
        server = Server((str(gateway), listen), Handler)
        server.allowed, server.target = network, target
        server.slots = threading.BoundedSemaphore(8)
        servers.append(server)
    threading.Thread(target=servers[0].serve_forever, daemon=True).start()
    servers[1].serve_forever()


if __name__ == '__main__':
    main()
