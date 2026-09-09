"""Expose the authenticated nutrition HTTP catalog as MCP tools over stdio."""
import asyncio
import re

from mcp.server.lowlevel import Server
from mcp.server.stdio import stdio_server

from api_client import legacy_configuration as configuration, legacy_request as api
from tool_catalog import make_tool

server = Server('nutrition-api')

@server.list_tools()
async def list_tools():
    catalog = await api('/queries')
    return [make_tool(operation, strict=False) for operation in catalog['data']]

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
