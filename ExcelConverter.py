import pandas as pd
import mysql.connector

conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='Admin',
    database='Project'
)


query = """select * from Project.Date_wise_supplier ;"""

df = pd.read_sql(query, conn)

# Export to Excel
df.to_excel('output.xlsx', index=False)

# Close the connection
conn.close()
