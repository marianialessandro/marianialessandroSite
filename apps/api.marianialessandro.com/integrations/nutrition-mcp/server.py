"""Expose the authenticated nutrition HTTP catalog as MCP tools over stdio."""
import asyncio
import copy
import os
import re
from urllib.parse import urlparse

import httpx
import mcp.types as types
from mcp.server.lowlevel import Server
from mcp.server.stdio import stdio_server

server = Server('nutrition-api')

def configuration():
    url = os.environ['NUTRITION_API_URL'].rstrip('/')
    parsed = urlparse(url)
    if parsed.scheme != 'https' and not (parsed.scheme == 'http' and parsed.hostname in ('localhost', '127.0.0.1', '::1')):
        raise ValueError('NUTRITION_API_URL must use HTTPS except on loopback.')
    if parsed.username or parsed.password or parsed.query or parsed.fragment:
        raise ValueError('NUTRITION_API_URL must not contain credentials, query or fragment.')
    return url, os.environ['NUTRITION_API_TOKEN']

async def api(path, payload=None):
    url, token = configuration()
    async with httpx.AsyncClient(timeout=30, follow_redirects=False) as client:
        response = await client.request('GET' if payload is None else 'POST', url + path, headers={'Authorization': 'Bearer ' + token, 'Accept': 'application/json'}, json=payload)
    if response.status_code >= 300:
        raise ValueError(f'Nutrition API returned HTTP {response.status_code}; verify token, permissions and parameters.')
    return response.json()

@server.list_tools()
async def list_tools():
    catalog = await api('/queries')
    tools = []
    for operation in catalog['data']:
        schema = copy.deepcopy(operation['inputSchema'])
        destructive = operation['ability'] in ('nutrition:delete', 'nutrition:maintenance')
        if destructive:
            schema['properties']['confirm'] = {'type': 'boolean', 'const': True, 'description': 'Explicit confirmation of deletion or maintenance.'}
            schema['required'].append('confirm')
        tools.append(types.Tool(name='nutrition_' + operation['id'].replace('.', '_'), description=operation['description'], inputSchema=schema, annotations=types.ToolAnnotations(readOnlyHint=operation['ability'] == 'nutrition:read', destructiveHint=destructive, openWorldHint=False)))
    return tools

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if not re.fullmatch(r'nutrition_\d+_\d+', name):
        raise ValueError('Unknown nutrition tool.')
    operation = name.removeprefix('nutrition_').replace('_', '.')
    parameters = dict(arguments)
    confirm = parameters.pop('confirm', None)
    payload = {'parameters': parameters}
    if confirm is not None:
        payload['confirm'] = confirm
    return await api('/queries/' + operation + '/execute', payload)

async def main():
    configuration()
    async with stdio_server() as (read, write):
        await server.run(read, write, server.create_initialization_options())

if __name__ == '__main__':
    asyncio.run(main())
