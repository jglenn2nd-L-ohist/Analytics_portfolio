import sqlite3
conn = sqlite3.connect("../data/lead_attribution.db")

conn.execute("""
    DELETE FROM hyros
    WHERE rowid NOT IN (
        SELECT MIN(rowid)
        FROM hyros
        GROUP BY "Unique ID"
    )
""")

conn.commit()

total = conn.execute("SELECT COUNT(*) FROM hyros").fetchone()
print("Rows after dedup:", total[0])
conn.close()