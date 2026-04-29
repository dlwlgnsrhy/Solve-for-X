import sqlite3
db_path = "/Users/apple/.hermes/state.db"
conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
c = conn.cursor()
c.execute("SELECT id, message_count FROM sessions ORDER BY started_at DESC LIMIT 5")
for r in c.fetchall():
    print(f"{r['id']}: {r['message_count']}")
