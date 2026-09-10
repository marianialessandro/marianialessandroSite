"""Exercise MCP initialization, discovery, authenticated calls and error handling."""
import asyncio
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import threading
import unittest

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

class Handler(BaseHTTPRequestHandler):
    requests = []

    def log_message(self, *args):
        pass

    def do_GET(self):
        self.requests.append(self.headers.get('Authorization'))
        schema = {'type': 'object', 'properties': {}, 'required': [], 'additionalProperties': False}
        data = {'data': [{'id': '6.1', 'description': 'Read', 'ability': 'nutrition:read', 'inputSchema': schema}, {'id': '17.10', 'description': 'Delete', 'ability': 'nutrition:delete', 'inputSchema': schema}]}
        self.send_response(200)
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_POST(self):
        self.requests.append(self.headers.get('Authorization'))
        payload = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        self.send_response(403 if '17.10' in self.path else 200)
        self.end_headers()
        self.wfile.write(json.dumps({'received': payload}).encode())

class McpTest(unittest.TestCase):
    def test_stdio_round_trip(self):
        http = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        threading.Thread(target=http.serve_forever, daemon=True).start()
        async def exercise():
            import sys
            parameters = StdioServerParameters(command=sys.executable, args=[str(Path(__file__).with_name('server.py'))], env={'NUTRITION_API_URL': f'http://127.0.0.1:{http.server_port}', 'NUTRITION_API_TOKEN': 'test-token'})
            async with stdio_client(parameters) as (read, write):
                async with ClientSession(read, write) as session:
                    await session.initialize()
                    listed = await session.list_tools()
                    self.assertEqual(2, len(listed.tools))
                    self.assertIn('confirm', listed.tools[1].inputSchema['required'])
                    result = await session.call_tool('nutrition_6_1', {})
                    self.assertFalse(result.isError)
                    self.assertEqual({'parameters': {}}, result.structuredContent['received'])
                    denied = await session.call_tool('nutrition_17_10', {'confirm': True})
                    self.assertTrue(denied.isError)
        try:
            asyncio.run(exercise())
            self.assertTrue(Handler.requests)
            self.assertTrue(all(token == 'Bearer test-token' for token in Handler.requests))
        finally:
            http.shutdown()
            http.server_close()

if __name__ == '__main__':
    unittest.main()
