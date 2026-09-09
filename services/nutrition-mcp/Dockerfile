FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.lock .
RUN pip install --no-cache-dir --require-hashes -r requirements.lock && useradd --uid 10001 --create-home mcp
COPY *.py ./
USER 10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s CMD python -c "import os,urllib.request,urllib.parse; host=urllib.parse.urlsplit(os.environ['MCP_RESOURCE']).netloc; urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8000/health',headers={'Host':host}),timeout=3)"
CMD ["python", "server.py", "--transport", "streamable-http", "--host", "0.0.0.0", "--port", "8000"]
