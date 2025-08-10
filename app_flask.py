from flask import Flask, request, jsonify
import sqlite3
import base64
import os
from datetime import datetime
from flask import render_template


app = Flask(__name__)
DB_FILE = "reportes.db"

# Crear la base de datos si no existe
def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS reportes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    lat REAL,
                    lon REAL,
                    fecha TEXT,
                    foto_base64 TEXT
                )''')
    conn.commit()
    conn.close()

init_db()

# Endpoint POST para recibir reportes
@app.route("/reportes", methods=["POST"])
def recibir_reporte():
    data = request.get_json()

    lat = data.get("lat")
    lon = data.get("lon")
    fecha = data.get("fecha", datetime.now().isoformat())
    foto_base64 = data.get("foto_base64")

    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute("INSERT INTO reportes (lat, lon, fecha, foto_base64) VALUES (?, ?, ?, ?)",
              (lat, lon, fecha, foto_base64))
    conn.commit()
    conn.close()

    return jsonify({"mensaje": "Reporte recibido con éxito"}), 201

# Endpoint GET para enviar todos los reportes
@app.route("/reportes", methods=["GET"])
def obtener_reportes():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute("SELECT lat, lon, fecha, foto_base64 FROM reportes")
    rows = c.fetchall()
    conn.close()

    reportes = []
    for r in rows:
        reportes.append({
            "lat": r[0],
            "lon": r[1],
            "fecha": r[2],
            "foto_base64": r[3]
        })

    return jsonify(reportes)

@app.route('/')
def home():
    return render_template('mapa.html')

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
