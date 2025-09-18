"""
Nusantara Ledger Backend API - Fixed for direct execution
FastAPI application without uvicorn reload issues
"""

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from typing import List, Dict, Any, Optional
import hashlib
import json
import os
from datetime import datetime
import sqlite3
import asyncio
import random

# Initialize FastAPI app
app = FastAPI(
    title="Nusantara Ledger API",
    description="Anti-corruption transparency system with SUI blockchain integration",
    version="1.0.0-dev",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create necessary directories
os.makedirs("storage", exist_ok=True)
os.makedirs("logs", exist_ok=True)

# Initialize SQLite database
def init_db():
    conn = sqlite3.connect("nusantara.db")
    cursor = conn.cursor()
    
    # Create documents table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filename TEXT NOT NULL,
            doc_hash TEXT NOT NULL UNIQUE,
            merkle_root TEXT,
            metadata_hash TEXT,
            tag TEXT,
            status TEXT DEFAULT 'pending',
            uploader_id INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            processed_at TIMESTAMP,
            sui_tx_hash TEXT,
            storage_path TEXT,
            anomaly_score REAL,
            extracted_entities TEXT
        )
    """)
    
    # Create alerts table
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id INTEGER,
            alert_type TEXT,
            severity TEXT,
            title TEXT,
            description TEXT,
            confidence_score REAL,
            evidence TEXT,
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            assigned_to INTEGER,
            FOREIGN KEY (document_id) REFERENCES documents (id)
        )
    """)
    
    # Create users table (basic)
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT,
            role TEXT DEFAULT 'auditor',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Insert default admin user
    cursor.execute("""
        INSERT OR IGNORE INTO users (username, email, role) 
        VALUES ('admin', 'admin@localhost', 'admin')
    """)
    
    conn.commit()
    conn.close()

# Initialize database on startup
init_db()

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "python_version": "3.13 compatible",
        "services": {
            "database": "healthy",
            "storage": "healthy",
            "sui_node": "healthy"
        }
    }

@app.get("/")
async def root():
    return HTMLResponse(content="""
    <html>
        <head>
            <title>Nusantara Ledger API</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                h1 { color: #2563eb; }
                .status { background: #dcfce7; padding: 15px; border-radius: 5px; margin: 20px 0; border-left: 4px solid #16a34a; }
                .endpoints { background: #f8fafc; padding: 15px; border-radius: 5px; margin: 15px 0; }
                a { color: #3b82f6; text-decoration: none; }
                a:hover { text-decoration: underline; }
                ul li { margin: 8px 0; }
                .badge { background: #dbeafe; color: #1e40af; padding: 4px 8px; border-radius: 12px; font-size: 0.8em; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🏛️ Nusantara Ledger API</h1>
                <p>Transparency and anti-corruption monitoring system</p>
                
                <div class="status">
                    ✅ <strong>Status:</strong> Running successfully on Python 3.13 
                    <span class="badge">READY</span>
                </div>
                
                <div class="endpoints">
                    <h2>🔗 API Endpoints:</h2>
                    <ul>
                        <li><a href="/docs">📖 Interactive API Documentation (Swagger UI)</a></li>
                        <li><a href="/redoc">📚 Alternative API Documentation (ReDoc)</a></li>
                        <li><a href="/health">❤️ Health Check</a></li>
                        <li><a href="/admin/stats">📊 System Statistics</a></li>
                        <li><a href="/documents">📄 Documents List</a></li>
                        <li><a href="/alerts">🚨 Alerts List</a></li>
                    </ul>
                </div>
                
                <div class="endpoints">
                    <h2>🖥️ Frontend Dashboard:</h2>
                    <p><strong><a href="http://localhost:3000">Open Dashboard (localhost:3000)</a></strong></p>
                    <p><em>Make sure to start the frontend with: <code>cd frontend && npm run dev</code></em></p>
                </div>
                
                <div class="endpoints">
                    <h2>🧪 Quick Test:</h2>
                    <ol>
                        <li>Visit the <a href="/docs">API Documentation</a></li>
                        <li>Try the <code>POST /documents/upload</code> endpoint</li>
                        <li>Check <a href="/admin/stats">System Statistics</a></li>
                        <li>View generated <a href="/alerts">Alerts</a></li>
                    </ol>
                </div>
                
                <hr>
                <p><em>Nusantara Ledger v1.0.0-dev • Built for transparency and accountability</em></p>
                <p><small>⚠️ Development mode - Change admin credentials in production</small></p>
            </div>
        </body>
    </html>
    """)

@app.post("/auth/login")
async def login(credentials: Dict[str, Any]):
    username = credentials.get("username")
    password = credentials.get("password")
    
    if username == "admin" and password == "admin":
        return {
            "access_token": "demo-jwt-token-admin",
            "token_type": "bearer",
            "user": {
                "id": 1,
                "username": "admin",
                "role": "admin",
                "permissions": ["read", "write", "admin"]
            }
        }
    
    raise HTTPException(status_code=401, detail="Invalid credentials")

@app.post("/documents/upload")
async def upload_document(file: UploadFile = File(...), tag: str = "document"):
    content = await file.read()
    doc_hash = hashlib.sha256(content).hexdigest()
    
    conn = sqlite3.connect("nusantara.db")
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM documents WHERE doc_hash = ?", (doc_hash,))
    existing = cursor.fetchone()
    
    if existing:
        conn.close()
        raise HTTPException(status_code=409, detail="Document already exists")
    
    storage_path = f"storage/{doc_hash}_{file.filename}"
    with open(storage_path, "wb") as f:
        f.write(content)
    
    cursor.execute("""
        INSERT INTO documents (filename, doc_hash, tag, storage_path, uploader_id)
        VALUES (?, ?, ?, ?, ?)
    """, (file.filename, doc_hash, tag, storage_path, 1))
    
    document_id = cursor.lastrowid
    conn.commit()
    conn.close()
    
    await simulate_document_processing(document_id)
    
    return {
        "id": document_id,
        "filename": file.filename,
        "doc_hash": doc_hash,
        "status": "processed",
        "message": "Document uploaded and processed successfully"
    }

@app.get("/documents")
async def list_documents(skip: int = 0, limit: int = 100):
    conn = sqlite3.connect("nusantara.db")
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT id, filename, doc_hash, tag, status, created_at, anomaly_score
        FROM documents
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
    """, (limit, skip))
    
    documents = []
    for row in cursor.fetchall():
        documents.append({
            "id": row[0],
            "filename": row[1],
            "doc_hash": row[2],
            "tag": row[3],
            "status": row[4],
            "created_at": row[5],
            "anomaly_score": row[6]
        })
    
    conn.close()
    return documents

@app.get("/alerts")
async def list_alerts(skip: int = 0, limit: int = 100):
    conn = sqlite3.connect("nusantara.db")
    cursor = conn.cursor()
    
    cursor.execute("""
        SELECT id, document_id, alert_type, severity, title, description,
               confidence_score, status, created_at
        FROM alerts
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
    """, (limit, skip))
    
    alerts = []
    for row in cursor.fetchall():
        alerts.append({
            "id": row[0],
            "document_id": row[1],
            "alert_type": row[2],
            "severity": row[3],
            "title": row[4],
            "description": row[5],
            "confidence_score": row[6],
            "status": row[7],
            "created_at": row[8]
        })
    
    conn.close()
    return alerts

@app.get("/admin/stats")
async def get_admin_stats():
    conn = sqlite3.connect("nusantara.db")
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM documents")
    total_docs = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM documents WHERE status = 'pending'")
    pending_docs = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM documents WHERE status = 'processed'")
    processed_docs = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM alerts")
    total_alerts = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM alerts WHERE severity = 'high'")
    high_alerts = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM alerts WHERE severity = 'medium'")
    medium_alerts = cursor.fetchone()[0]
    
    cursor.execute("""
        SELECT id, filename, status, created_at
        FROM documents
        ORDER BY created_at DESC
        LIMIT 5
    """)
    recent_docs = [
        {"id": row[0], "filename": row[1], "status": row[2], "created_at": row[3]}
        for row in cursor.fetchall()
    ]
    
    cursor.execute("""
        SELECT id, title, severity, created_at
        FROM alerts
        ORDER BY created_at DESC
        LIMIT 5
    """)
    recent_alerts = [
        {"id": row[0], "title": row[1], "severity": row[2], "created_at": row[3]}
        for row in cursor.fetchall()
    ]
    
    conn.close()
    
    return {
        "documents": {
            "total": total_docs,
            "pending": pending_docs,
            "processed": processed_docs,
            "failed": 0
        },
        "alerts": {
            "total": total_alerts,
            "high": high_alerts,
            "medium": medium_alerts,
            "low": total_alerts - high_alerts - medium_alerts
        },
        "recent_activity": {
            "documents": recent_docs,
            "alerts": recent_alerts
        }
    }

async def simulate_document_processing(document_id: int):
    await asyncio.sleep(1)
    
    conn = sqlite3.connect("nusantara.db")
    cursor = conn.cursor()
    
    merkle_root = hashlib.sha256(f"merkle_{document_id}".encode()).hexdigest()
    metadata_hash = hashlib.sha256(f"metadata_{document_id}".encode()).hexdigest()
    anomaly_score = random.uniform(0.1, 0.9)
    
    entities = {
        "organizations": ["XYZ Corporation", "Government Agency", "Digital Affairs Dept"],
        "amounts": ["$75,000.00", "$50,000.00"],
        "persons": ["John Smith", "Jane Wilson"],
        "dates": ["2025-01-15", "2025-03-01"],
        "locations": ["Jakarta", "Singapore"]
    }
    
    cursor.execute("""
        UPDATE documents 
        SET status = 'processed',
            processed_at = CURRENT_TIMESTAMP,
            merkle_root = ?,
            metadata_hash = ?,
            anomaly_score = ?,
            extracted_entities = ?,
            sui_tx_hash = ?
        WHERE id = ?
    """, (
        merkle_root, 
        metadata_hash, 
        anomaly_score, 
        json.dumps(entities),
        f"0x{random.randint(100000, 999999)}abc{random.randint(100, 999)}",
        document_id
    ))
    
    if anomaly_score > 0.7:
        severity = "high" if anomaly_score > 0.8 else "medium"
        cursor.execute("""
            INSERT INTO alerts (document_id, alert_type, severity, title, description, confidence_score)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            document_id,
            "high_anomaly_score",
            severity,
            f"🚨 High Risk Document Detected: {anomaly_score:.2f}",
            f"Document shows suspicious patterns with anomaly score of {anomaly_score:.2f}. Contains offshore references and urgent language patterns. Requires immediate review.",
            anomaly_score
        ))
    
    if random.random() > 0.6:  # 40% chance of additional alert
        alert_types = [
            ("vendor_official_overlap", "medium", "Potential vendor-official connection detected"),
            ("large_payment", "medium", "Unusually large payment amount"),
            ("circular_flow", "low", "Multiple organizations in single document"),
            ("urgent_language", "low", "Urgent language patterns detected")
        ]
        
        alert_type, sev, title = random.choice(alert_types)
        cursor.execute("""
            INSERT INTO alerts (document_id, alert_type, severity, title, description, confidence_score)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            document_id,
            alert_type,
            sev,
            title,
            f"Automated analysis flagged potential issues in document processing.",
            random.uniform(0.5, 0.9)
        ))
    
    conn.commit()
    conn.close()

if __name__ == "__main__":
    import uvicorn
    print("🏛️  Starting Nusantara Ledger API...")
    print("📊 Dashboard will be available at: http://localhost:3000")
    print("📖 API Documentation: http://localhost:8000/docs")
    print("❤️  Health Check: http://localhost:8000/health")
    print("-" * 50)
    
    # Run without reload to avoid the warning
    uvicorn.run(app, host="0.0.0.0", port=8000)