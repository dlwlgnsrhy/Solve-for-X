import sqlite3
import json

db_path = "/Users/apple/.hermes/state.db"
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
c = conn.cursor()
c.execute("SELECT content, tool_calls FROM messages WHERE session_id = '20260429_194009_8ce01e' AND role = 'assistant' ORDER BY timestamp DESC LIMIT 5")
rows = c.fetchall()
for r in rows:
    print(f"Content: {r['content']}")
    print(f"Tool: {r['tool_calls']}")
    print("---")
