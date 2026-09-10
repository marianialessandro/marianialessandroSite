"""Nutrition MCP: backwards-compatible stdio or authenticated Streamable HTTP."""
import argparse
import asyncio
import logging


def parser():
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument('--transport', choices=['stdio', 'streamable-http'], default='stdio', help='Transport (default: stdio with NUTRITION_API_URL/NUTRITION_API_TOKEN).')
    result.add_argument('--host', default='127.0.0.1', help='HTTP bind address (default: 127.0.0.1).')
    result.add_argument('--port', type=int, default=8000, help='HTTP bind port (default: 8000).')
    return result


def main(argv=None):
    args = parser().parse_args(argv)
    if args.transport == 'stdio':
        from legacy_stdio import main as run_stdio
        asyncio.run(run_stdio())
    else:
        import uvicorn
        from configuration import Settings
        from http_app import create_app
        logging.basicConfig(level=logging.WARNING)
        logging.getLogger('nutrition.audit').setLevel(logging.INFO)
        try:
            app = create_app(Settings.from_env())
        except (KeyError, ValueError):
            raise SystemExit('Invalid or incomplete MCP configuration; see .env.example.') from None
        uvicorn.run(app, host=args.host, port=args.port, access_log=False, proxy_headers=False, log_level='warning')


if __name__ == '__main__':
    main()
