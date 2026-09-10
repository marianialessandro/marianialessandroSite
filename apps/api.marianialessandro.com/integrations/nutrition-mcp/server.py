"""Compatible entry point; the standalone MCP service lives in services/nutrition-mcp."""
from pathlib import Path
import runpy
import sys

ROOT = Path(__file__).resolve().parents[4] / 'services' / 'nutrition-mcp'
sys.path.insert(0, str(ROOT))

if __name__ == '__main__':
    runpy.run_path(str(ROOT / 'server.py'), run_name='__main__')
