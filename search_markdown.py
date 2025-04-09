import sys
sys.path.insert(0, "./libs")

from mcp.server.fastmcp import FastMCP
from pathlib import Path
from urllib.parse import quote
import requests

app = FastMCP("Markdown Search")

def search_markdown(q: str):
    try:
        encoded_q = quote(q, safe="")
        url = f"http://localhost:5555/search?q={encoded_q}"

        res = requests.get(url)
        res.raise_for_status()
        data = res.json()
        return {
            "status": "ok",
            "query": q,
            "results": data.get("results", [])
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }

app.tool()(search_markdown)

if __name__ == "__main__":
    app.run()
