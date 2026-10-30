"""Real socket checks for the private, bounded Keycloak test-mail forwarder."""
import importlib.util
import ipaddress
from pathlib import Path
import socket
import socketserver
import threading
import unittest

spec = importlib.util.spec_from_file_location('capture_forward', Path(__file__).resolve().parents[1] / 'roles/keycloak_application/files/capture_forward.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class Echo(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.settimeout(2)
        try:
            while True:
                data = self.request.recv(16384)
                if not data:
                    return
                self.request.sendall(data)
        except OSError:
            pass


class EchoServer(socketserver.ThreadingTCPServer):
    daemon_threads = True


class CaptureForwardTests(unittest.TestCase):
    def run_proxy(self, allowed, message):
        with EchoServer(('127.0.0.1', 0), Echo) as upstream:
            with module.Server(('127.0.0.1', 0), module.Handler) as proxy:
                proxy.allowed = ipaddress.ip_network(allowed)
                proxy.target = upstream.server_address[1]
                proxy.slots = threading.BoundedSemaphore(8)
                threads = [threading.Thread(target=server.serve_forever) for server in (upstream, proxy)]
                for thread in threads:
                    thread.start()
                try:
                    with socket.create_connection(proxy.server_address, timeout=3) as client:
                        client.settimeout(3)
                        client.sendall(message)
                        return client.recv(len(message))
                finally:
                    proxy.shutdown()
                    upstream.shutdown()
                    for thread in threads:
                        thread.join()

    def test_allowed_capture_bytes_cross_the_private_forwarder(self):
        message = b'EHLO capture-check\r\n'
        self.assertEqual(self.run_proxy('127.0.0.0/8', message), message)

    def test_a_source_outside_the_allowed_network_is_rejected(self):
        self.assertEqual(self.run_proxy('10.0.0.0/8', b'EHLO refused\r\n'), b'')
