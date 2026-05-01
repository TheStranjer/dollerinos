#!/usr/bin/env python3
"""
MCP Diagnostic Script for hellthread (or any MCP server)
Run this against your current endpoint to see exactly why xAI/rmcp gets "Tool not available".

It performs the exact handshake xAI does, then issues a real tools/call.
It inspects whether the server returns proper Streaming HTTP / SSE / chunked responses
(the thing xAI strictly requires for tools/call).

Usage:
    python3 diagnose_mcp.py https://hellthread.cyou/mcp/messages
    # or with auth:
    python3 diagnose_mcp.py https://hellthread.cyou/mcp/messages --auth "Bearer xTcPqGhXBHSulBE7CR6KEg=="
"""

import json
import sys
import requests
from urllib.parse import urlparse

def print_header(title):
    print("\n" + "="*80)
    print(title)
    print("="*80)

def post_json(url, payload, auth_header=None, stream=False):
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/event-stream",  # xAI sends this
    }
    if auth_header:
        headers["Authorization"] = auth_header

    response = requests.post(
        url,
        json=payload,
        headers=headers,
        stream=stream,
        timeout=30
    )

    print(f"Status: {response.status_code} {response.reason}")
    print("Headers:")
    for k, v in response.headers.items():
        print(f"  {k}: {v}")

    # Show if it's streaming
    is_chunked = response.headers.get("Transfer-Encoding") == "chunked"
    is_sse = "text/event-stream" in response.headers.get("Content-Type", "")
    print(f"→ Streaming HTTP? chunked={is_chunked} | SSE={is_sse}")

    if stream:
        print("First 3 lines of body (streaming):")
        try:
            lines = list(response.iter_lines(decode_unicode=True))[:3]
            print(json.dumps(lines, indent=2))
        except Exception as e:
            print(f"Error reading stream: {e}")
    else:
        try:
            data = response.json()
            print("Body (JSON):")
            print(json.dumps(data, indent=2))
        except Exception:
            print("Body (raw):")
            print(response.text[:1000])

    return response

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 diagnose_mcp.py <endpoint> [--auth \"Bearer ...\"]")
        sys.exit(1)

    endpoint = sys.argv[1].rstrip("/")
    auth = None
    if "--auth" in sys.argv:
        idx = sys.argv.index("--auth") + 1
        if idx < len(sys.argv):
            auth = sys.argv[idx]

    print_header(f"DIAGNOSTIC RUN AGAINST: {endpoint}")

    # 1. initialize (exactly what xAI sends)
    init_payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2025-03-26",
            "capabilities": {},
            "clientInfo": {"name": "diagnostic-script", "version": "1.0"}
        }
    }
    post_json(endpoint, init_payload, auth)

    # 2. notifications/initialized (no id, fire-and-forget)
    print_header("notifications/initialized")
    notif_payload = {
        "jsonrpc": "2.0",
        "method": "notifications/initialized"
    }
    post_json(endpoint, notif_payload, auth)

    # 3. tools/list
    print_header("tools/list")
    list_payload = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/list",
        "params": {"_meta": {"progressToken": None}}
    }
    list_resp = post_json(endpoint, list_payload, auth)

    # Extract first tool for testing
    try:
        tools = list_resp.json()["result"]["tools"]
        if not tools:
            print("ERROR: No tools returned!")
            sys.exit(1)
        tool_name = tools[0]["name"]
        print(f"\n→ Will test tools/call on first tool: {tool_name}")
    except Exception as e:
        print(f"Could not parse tools/list: {e}")
        sys.exit(1)

    # 4. tools/call (this is where xAI fails with "Tool not available")
    print_header(f"tools/call → {tool_name}")
    call_payload = {
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": tool_name,
            "arguments": {}   # empty is fine for most tools
        }
    }
    # Use stream=True so we can see if it's SSE / chunked
    post_json(endpoint, call_payload, auth, stream=True)

    print_header("SUMMARY")
    print("If the tools/call section above shows:")
    print("  • Status 200 but NOT chunked and NOT text/event-stream")
    print("  • A plain JSON-RPC response instead of streaming events")
    print("→ That is the exact incompatibility with xAI/rmcp v0.8.5.")
    print("\nFix: Make your Mcp::MessagesController support Streaming HTTP / SSE")
    print("     for tools/call (return text/event-stream with data: lines).")
    print("     Many MCP frameworks have a 'streaming' mode — enable it.")

if __name__ == "__main__":
    main()

