# Bridge MCP compatibile

`python server.py` mantiene stdio e le variabili `NUTRITION_API_URL`/`NUTRITION_API_TOKEN`. I flag opzionali `--transport`, `--host`, `--port` sono descritti in `python server.py --help`.

Il codice condiviso e il server remoto OAuth/Streamable HTTP vivono nella directory indipendente [`services/nutrition-mcp`](../../../../services/nutrition-mcp/README.md). Per HTTP usare Python 3.12 e il lock del nuovo servizio. Il test storico `test_server.py` continua a verificare l'entry point originale.
