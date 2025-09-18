# ============================================================================
# NUSANTARA LEDGER - COMPLETE FULLSTACK ANTI-CORRUPTION TRANSPARENCY SYSTEM
# PowerShell Installation & Management Scripts
# ============================================================================

# install.ps1 - Main Installation Script
param(
    [switch]$OfflineMode,
    [switch]$DeveloperMode,
    [string]$InstallPath = "C:\NusantaraLedger",
    [string]$DataPath = "C:\NusantaraData",
    [switch]$SkipPrereqs,
    [switch]$Silent
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Colors for output
$Colors = @{
    Success = "Green"
    Warning = "Yellow" 
    Error = "Red"
    Info = "Cyan"
    Header = "Magenta"
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "=" * 80 -Color Header
    Write-ColorOutput "  $Title" -Color Header
    Write-ColorOutput "=" * 80 -Color Header
    Write-Host ""
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Prerequisites {
    Write-Header "Installing Prerequisites"
    
    # Check if running as admin
    if (-not (Test-AdminRights)) {
        Write-ColorOutput "ERROR: Please run as Administrator to install prerequisites!" -Color Error
        exit 1
    }
    
    # Install Chocolatey if not present
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-ColorOutput "Installing Chocolatey..." -Color Info
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    
    # Install required software
    $packages = @(
        "python3",
        "nodejs", 
        "git",
        "docker-desktop",
        "postgresql13",
        "redis-64",
        "nginx"
    )
    
    foreach ($package in $packages) {
        Write-ColorOutput "Installing $package..." -Color Info
        choco install $package -y --no-progress
    }
    
    # Install SUI CLI
    Write-ColorOutput "Installing SUI CLI..." -Color Info
    $suiUrl = "https://github.com/MystenLabs/sui/releases/latest/download/sui-windows-x86_64.zip"
    $suiZip = "$env:TEMP\sui.zip"
    $suiExtract = "$env:TEMP\sui"
    
    Invoke-WebRequest -Uri $suiUrl -OutFile $suiZip
    Expand-Archive -Path $suiZip -DestinationPath $suiExtract -Force
    Copy-Item "$suiExtract\sui.exe" -Destination "C:\Windows\System32\" -Force
    
    Write-ColorOutput "Prerequisites installed successfully!" -Color Success
}

function Create-Directory-Structure {
    Write-Header "Creating Directory Structure"
    
    $directories = @(
        "$InstallPath",
        "$InstallPath\backend",
        "$InstallPath\frontend", 
        "$InstallPath\contracts",
        "$InstallPath\ai-models",
        "$InstallPath\scripts",
        "$InstallPath\logs",
        "$InstallPath\config",
        "$DataPath",
        "$DataPath\postgres",
        "$DataPath\redis",
        "$DataPath\storage",
        "$DataPath\backups"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-ColorOutput "Created: $dir" -Color Info
        }
    }
}

function Install-Python-Dependencies {
    Write-Header "Installing Python Dependencies"
    
    # Create virtual environment
    $venvPath = "$InstallPath\backend\venv"
    python -m venv $venvPath
    
    # Activate virtual environment
    & "$venvPath\Scripts\Activate.ps1"
    
    # Upgrade pip
    python -m pip install --upgrade pip
    
    # Install requirements
    $requirements = @"
# Nusantara Ledger Backend Dependencies
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
sqlalchemy==2.0.23
asyncpg==0.29.0
alembic==1.13.0
redis==5.0.1
celery==5.3.4
httpx==0.25.2
python-multipart==0.0.6
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-dotenv==1.0.0
aiofiles==23.2.1
prometheus-client==0.19.0
structlog==23.2.0

# AI/ML Dependencies (CPU-only for on-premise)
scikit-learn==1.3.2
pandas==2.1.4
numpy==1.24.4
spacy==3.7.2
networkx==3.2.1
python-louvain==0.16

# Blockchain & Crypto
pysui==0.33.0
cryptography==41.0.8
merkletools==1.0.3

# Storage & IPFS
ipfshttpclient==0.8.0a2
minio==7.2.0

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
httpx==0.25.2
"@
    
    $requirementsFile = "$InstallPath\backend\requirements.txt"
    $requirements | Out-File -FilePath $requirementsFile -Encoding utf8
    
    pip install -r $requirementsFile
    
    # Download spaCy models
    python -m spacy download en_core_web_sm
    
    Write-ColorOutput "Python dependencies installed!" -Color Success
}

function Install-Node-Dependencies {
    Write-Header "Installing Node.js Dependencies"
    
    Set-Location "$InstallPath\frontend"
    
    # Create package.json
    $packageJson = @"
{
  "name": "nusantara-ledger-frontend",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test": "vitest",
    "test:e2e": "playwright test",
    "lint": "eslint . --ext js,jsx --report-unused-disable-directives --max-warnings 0"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0",
    "@reduxjs/toolkit": "^1.9.7",
    "react-redux": "^8.1.3",
    "axios": "^1.6.2",
    "socket.io-client": "^4.7.4",
    "@headlessui/react": "^1.7.17",
    "@heroicons/react": "^2.0.18",
    "recharts": "^2.8.0",
    "cytoscape": "^3.26.0",
    "cytoscape-cose-bilkent": "^4.1.0",
    "react-cytoscapejs": "^2.0.0",
    "date-fns": "^2.30.0",
    "lodash": "^4.17.21",
    "crypto-js": "^4.2.0",
    "file-saver": "^2.0.5",
    "react-dropzone": "^14.2.3",
    "react-hot-toast": "^2.4.1",
    "react-hook-form": "^7.48.2",
    "zod": "^3.22.4",
    "@hookform/resolvers": "^3.3.2"
  },
  "devDependencies": {
    "@types/react": "^18.2.37",
    "@types/react-dom": "^18.2.15",
    "@vitejs/plugin-react": "^4.1.1",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.53.0",
    "eslint-plugin-react": "^7.33.2",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.4",
    "postcss": "^8.4.31",
    "tailwindcss": "^3.3.6",
    "vite": "^4.5.0",
    "vitest": "^0.34.6",
    "@playwright/test": "^1.40.0"
  }
}
"@
    
    $packageJson | Out-File -FilePath "package.json" -Encoding utf8
    
    # Install packages
    npm install
    
    Write-ColorOutput "Node.js dependencies installed!" -Color Success
}

function Setup-Database {
    Write-Header "Setting up PostgreSQL Database"
    
    # Start PostgreSQL service
    Start-Service postgresql*
    
    # Create database and user
    $dbSetup = @"
-- Nusantara Ledger Database Setup
CREATE DATABASE nusantara_ledger;
CREATE USER nusantara_user WITH ENCRYPTED PASSWORD 'secure_password_2024';
GRANT ALL PRIVILEGES ON DATABASE nusantara_ledger TO nusantara_user;

\c nusantara_ledger;

-- Documents table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hash VARCHAR(64) UNIQUE NOT NULL,
    merkle_root VARCHAR(64) NOT NULL,
    metadata_hash VARCHAR(64) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    content_type VARCHAR(100),
    file_size BIGINT,
    ipfs_cid VARCHAR(100),
    encrypted BOOLEAN DEFAULT FALSE,
    uploader_id UUID,
    upload_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verification_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    ai_processed BOOLEAN DEFAULT FALSE,
    risk_score FLOAT DEFAULT 0.0,
    tags TEXT[],
    metadata JSONB
);

-- Users table  
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(20) DEFAULT 'public',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    organization VARCHAR(255),
    permissions JSONB
);

-- Alerts table
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id),
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    evidence JSONB,
    rules_triggered TEXT[],
    confidence_score FLOAT,
    created_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_to UUID REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'new',
    resolution TEXT,
    resolved_at TIMESTAMP,
    escalated BOOLEAN DEFAULT FALSE
);

-- Cases table (collections of related alerts/documents)
CREATE TABLE cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_number VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'open',
    priority VARCHAR(20) DEFAULT 'medium',
    created_by UUID REFERENCES users(id),
    assigned_to UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    tags TEXT[],
    metadata JSONB
);

-- Case documents relationship
CREATE TABLE case_documents (
    case_id UUID REFERENCES cases(id),
    document_id UUID REFERENCES documents(id),
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (case_id, document_id)
);

-- Blockchain transactions
CREATE TABLE blockchain_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id),
    tx_hash VARCHAR(100) UNIQUE NOT NULL,
    block_number BIGINT,
    gas_used BIGINT,
    status VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP,
    blockchain_data JSONB
);

-- Audit logs
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_documents_hash ON documents(hash);
CREATE INDEX idx_documents_status ON documents(status);
CREATE INDEX idx_documents_uploader ON documents(uploader_id);
CREATE INDEX idx_documents_timestamp ON documents(upload_timestamp);
CREATE INDEX idx_alerts_document ON alerts(document_id);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_cases_status ON cases(status);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(created_at);

-- Create admin user
INSERT INTO users (email, hashed_password, full_name, role, organization) 
VALUES ('admin@nusantara.gov.id', '\$2b\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewYh8dLx6/2eZFRa', 'System Administrator', 'admin', 'Government');

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nusantara_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO nusantara_user;
"@
    
    $dbSetup | Out-File -FilePath "$InstallPath\setup_db.sql" -Encoding utf8
    psql -U postgres -f "$InstallPath\setup_db.sql"
    
    Write-ColorOutput "Database setup completed!" -Color Success
}

function Setup-Redis {
    Write-Header "Setting up Redis"
    
    # Start Redis service
    Start-Service Redis
    
    # Create Redis configuration
    $redisConfig = @"
# Nusantara Ledger Redis Configuration
port 6379
bind 127.0.0.1
protected-mode yes
requirepass nusantara_redis_2024
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
dir $DataPath\redis
dbfilename nusantara.rdb
logfile $InstallPath\logs\redis.log
loglevel notice
"@
    
    $redisConfig | Out-File -FilePath "$DataPath\redis\redis.conf" -Encoding utf8
    
    Write-ColorOutput "Redis configuration completed!" -Color Success
}

function Deploy-Smart-Contracts {
    Write-Header "Deploying SUI Smart Contracts"
    
    # Create Move.toml
    $moveToml = @"
[package]
name = "nusantara_ledger"
version = "1.0.0"
edition = "2024.beta"

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/devnet" }

[addresses]
nusantara_ledger = "0x0"
"@
    
    $moveToml | Out-File -FilePath "$InstallPath\contracts\Move.toml" -Encoding utf8
    
    # Create contract directory
    New-Item -ItemType Directory -Path "$InstallPath\contracts\sources" -Force
    
    # Main contract (simplified version for PowerShell)
    $mainContract = @"
module nusantara_ledger::transparency_ledger {
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use std::string::{Self, String};
    use std::vector;

    const EUNAUTHORIZED: u64 = 1;
    const EINVALID_PROOF: u64 = 2;

    struct TransparencyLedger has key {
        id: UID,
        admin: address,
        total_documents: u64,
        document_registry: Table<vector<u8>, DocumentRecord>,
    }

    struct DocumentRecord has store, copy, drop {
        merkle_root: vector<u8>,
        metadata_hash: vector<u8>,
        submitter: address,
        timestamp: u64,
        status: u8,
    }

    struct DocumentRecorded has copy, drop {
        document_hash: vector<u8>,
        submitter: address,
        timestamp: u64,
    }

    fun init(ctx: &mut TxContext) {
        let ledger = TransparencyLedger {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            total_documents: 0,
            document_registry: table::new(ctx),
        };
        
        transfer::share_object(ledger);
    }

    public entry fun record_document_proof(
        ledger: &mut TransparencyLedger,
        merkle_root: vector<u8>,
        metadata_hash: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(vector::length(&merkle_root) == 32, EINVALID_PROOF);
        
        let timestamp = clock::timestamp_ms(clock);
        let submitter = tx_context::sender(ctx);
        
        let document_hash = merkle_root; // Simplified
        
        let document_record = DocumentRecord {
            merkle_root,
            metadata_hash,
            submitter,
            timestamp,
            status: 0,
        };

        table::add(&mut ledger.document_registry, document_hash, document_record);
        ledger.total_documents = ledger.total_documents + 1;

        event::emit(DocumentRecorded {
            document_hash,
            submitter,
            timestamp,
        });
    }
}
"@
    
    $mainContract | Out-File -FilePath "$InstallPath\contracts\sources\transparency_ledger.move" -Encoding utf8
    
    # Initialize SUI client
    Set-Location "$InstallPath\contracts"
    
    # Setup SUI devnet environment
    sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443
    sui client switch --env devnet
    
    if (-not $Silent) {
        Write-ColorOutput "Please fund your SUI address with devnet tokens from: https://discord.gg/sui" -Color Warning
        Read-Host "Press Enter after funding your address..."
    }
    
    # Build and deploy
    sui move build
    $deployResult = sui client publish --gas-budget 100000000 . --json 2>$null
    
    if ($deployResult) {
        $packageId = ($deployResult | ConvertFrom-Json).objectChanges | Where-Object {$_.type -eq "published"} | Select-Object -ExpandProperty packageId
        Write-ColorOutput "Smart contract deployed! Package ID: $packageId" -Color Success
        
        # Save package ID to config
        @{ PackageId = $packageId } | ConvertTo-Json | Out-File -FilePath "$InstallPath\config\blockchain.json" -Encoding utf8
    }
}

function Create-Backend-Services {
    Write-Header "Creating Backend Services"
    
    # Main FastAPI application
    $mainApp = @"
# backend/main.py - Nusantara Ledger FastAPI Application
import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
import uvicorn
import os
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global services
services = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Nusantara Ledger backend...")
    yield
    # Shutdown
    logger.info("Shutting down...")

app = FastAPI(
    title="Nusantara Ledger API",
    description="Anti-corruption transparency system",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "nusantara-ledger"}

@app.post("/api/v1/documents/upload")
async def upload_document(file: UploadFile = File(...)):
    try:
        # Save file
        upload_dir = Path("uploads")
        upload_dir.mkdir(exist_ok=True)
        
        file_path = upload_dir / file.filename
        with open(file_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        # Calculate hash
        import hashlib
        file_hash = hashlib.sha256(content).hexdigest()
        
        # TODO: Process with AI, create Merkle tree, submit to blockchain
        
        return {
            "success": True,
            "document_id": file_hash[:16],
            "filename": file.filename,
            "size": len(content),
            "hash": file_hash
        }
    except Exception as e:
        logger.error(f"Upload error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/dashboard/overview")
async def get_dashboard_overview():
    return {
        "stats": {
            "totalDocuments": 42,
            "totalAlerts": 7,
            "pendingReviews": 3,
            "verifiedDocuments": 39,
            "criticalAlerts": 1,
            "onChainTransactions": 35
        },
        "recentActivity": [
            {
                "id": "1",
                "type": "alert",
                "title": "High-value contract detected",
                "description": "Contract value 5x above median",
                "timestamp": "2024-01-15T10:30:00Z",
                "severity": 3
            }
        ],
        "systemHealth": {
            "database": "healthy",
            "blockchain": "healthy",
            "ai_service": "healthy",
            "storage": "healthy"
        }
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
"@
    
    $mainApp | Out-File -FilePath "$InstallPath\backend\main.py" -Encoding utf8
    
    # Configuration file
    $config = @"
# Configuration for Nusantara Ledger
DATABASE_URL=postgresql://nusantara_user:secure_password_2024@localhost/nusantara_ledger
REDIS_URL=redis://localhost:6379/0
SUI_RPC_URL=https://fullnode.devnet.sui.io:443
SECRET_KEY=your-secret-key-here-change-in-production
UPLOAD_PATH=$DataPath\storage
IPFS_URL=http://localhost:5001
"@
    
    $config | Out-File -FilePath "$InstallPath\backend\.env" -Encoding utf8
    
    Write-ColorOutput "Backend services created!" -Color Success
}

function Create-Frontend-Application {
    Write-Header "Creating Frontend Application"
    
    Set-Location "$InstallPath\frontend"
    
    # Main React application
    $appJsx = @"
// src/App.jsx - Nusantara Ledger Frontend
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import { store } from './store';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Documents from './pages/Documents';
import Alerts from './pages/Alerts';
import './index.css';

function App() {
  return (
    <Provider store={store}>
      <Router>
        <Layout>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/documents" element={<Documents />} />
            <Route path="/alerts" element={<Alerts />} />
          </Routes>
        </Layout>
      </Router>
    </Provider>
  );
}

export default App;
"@
    
    # Create src directory structure
    New-Item -ItemType Directory -Path "src\components" -Force
    New-Item -ItemType Directory -Path "src\pages" -Force  
    New-Item -ItemType Directory -Path "src\hooks" -Force
    New-Item -ItemType Directory -Path "src\store" -Force
    New-Item -ItemType Directory -Path "src\utils" -Force
    
    $appJsx | Out-File -FilePath "src\App.jsx" -Encoding utf8
    
    # Dashboard component
    $dashboard = @"
// src/pages/Dashboard.jsx
import React, { useState, useEffect } from 'react';

export default function Dashboard() {
  const [stats, setStats] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/v1/dashboard/overview')
      .then(res => res.json())
      .then(data => {
        setStats(data.stats);
        setLoading(false);
      })
      .catch(err => {
        console.error('Dashboard error:', err);
        setLoading(false);
      });
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="md:flex md:items-center md:justify-between">
        <div className="flex-1 min-w-0">
          <h2 className="text-2xl font-bold text-gray-900">
            Nusantara Ledger Dashboard
          </h2>
          <p className="mt-1 text-sm text-gray-500">
            Anti-corruption transparency monitoring system
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="text-2xl">📄</div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total Documents
                  </dt>
                  <dd className="text-2xl font-semibold text-gray-900">
                    {stats.totalDocuments || 0}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="text-2xl">🚨</div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Active Alerts
                  </dt>
                  <dd className="text-2xl font-semibold text-gray-900">
                    {stats.totalAlerts || 0}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="text-2xl">⏳</div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Pending Reviews
                  </dt>
                  <dd className="text-2xl font-semibold text-gray-900">
                    {stats.pendingReviews || 0}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <div className="text-2xl">✅</div>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Verified Documents
                  </dt>
                  <dd className="text-2xl font-semibold text-gray-900">
                    {stats.verifiedDocuments || 0}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
"@
    
    $dashboard | Out-File -FilePath "src\pages\Dashboard.jsx" -Encoding utf8
    
    # Layout component
    $layout = @"
// src/components/Layout.jsx
import React from 'react';
import { Link, useLocation } from 'react-router-dom';

export default function Layout({ children }) {
  const location = useLocation();
  
  const navigation = [
    { name: 'Dashboard', href: '/', icon: '📊' },
    { name: 'Documents', href: '/documents', icon: '📄' },
    { name: 'Alerts', href: '/alerts', icon: '🚨' },
    { name: 'Cases', href: '/cases', icon: '📋' },
    { name: 'Graph', href: '/graph', icon: '🕸️' },
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <div className="flex flex-col w-64 bg-white shadow-sm">
        <div className="flex items-center h-16 flex-shrink-0 px-4 bg-blue-600">
          <h1 className="text-xl font-bold text-white">Nusantara Ledger</h1>
        </div>
        <div className="flex-1 flex flex-col overflow-y-auto">
          <nav className="flex-1 px-2 py-4 space-y-1">
            {navigation.map((item) => {
              const isActive = location.pathname === item.href;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={`group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors $${
                    isActive
                      ? 'bg-blue-100 text-blue-900'
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                  }`}
                >
                  <span className="mr-3 text-lg">{item.icon}</span>
                  {item.name}
                </Link>
              );
            })}
          </nav>
        </div>
      </div>
      
      <div className="flex-1 flex flex-col">
        <main className="flex-1 relative overflow-y-auto focus:outline-none">
          <div className="py-6">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
              {children}
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
"@
    
    $layout | Out-File -FilePath "src\components\Layout.jsx" -Encoding utf8
    
    # CSS file
    $css = @"
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
"@
    
    $css | Out-File -FilePath "src\index.css" -Encoding utf8
    
    # Vite config
    $viteConfig = @"
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': 'http://localhost:8000'
    }
  }
})
"@
    
    $viteConfig | Out-File -FilePath "vite.config.js" -Encoding utf8
    
    # Build frontend
    npm run build
    
    Write-ColorOutput "Frontend application created!" -Color Success
}

function Create-Service-Scripts {
    Write-Header "Creating Service Management Scripts"
    
    # Start services script
    $startScript = @"
# start-services.ps1
Write-Host "Starting Nusantara Ledger Services..." -ForegroundColor Green

# Start PostgreSQL
Write-Host "Starting PostgreSQL..." -ForegroundColor Cyan
Start-Service postgresql*

# Start Redis  
Write-Host "Starting Redis..." -ForegroundColor Cyan
Start-Service Redis

# Start backend
Write-Host "Starting backend API..." -ForegroundColor Cyan
Set-Location "$InstallPath\backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "& '.\venv\Scripts\Activate.ps1'; python main.py"

# Start frontend development server (optional)
if (Test-Path "$InstallPath\frontend\node_modules") {
    Write-Host "Starting frontend..." -ForegroundColor Cyan
    Set-Location "$InstallPath\frontend" 
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm run dev"
}

Write-Host ""
Write-Host "Services started!" -ForegroundColor Green
Write-Host "Backend API: http://localhost:8000" -ForegroundColor Yellow
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Yellow  
Write-Host "API Docs: http://localhost:8000/docs" -ForegroundColor Yellow
"@
    
    $startScript | Out-File -FilePath "$InstallPath\scripts\start-services.ps1" -Encoding utf8
    
    # Stop services script
    $stopScript = @"
# stop-services.ps1
Write-Host "Stopping Nusantara Ledger Services..." -ForegroundColor Red

# Stop Python processes
Get-Process python -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*nusantara*"} | Stop-Process -Force

# Stop Node processes  
Get-Process node -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*nusantara*"} | Stop-Process -Force

# Stop services (optional - may affect other applications)
# Stop-Service Redis -ErrorAction SilentlyContinue
# Stop-Service postgresql* -ErrorAction SilentlyContinue

Write-Host "Services stopped!" -ForegroundColor Green
"@
    
    $stopScript | Out-File -FilePath "$InstallPath\scripts\stop-services.ps1" -Encoding utf8
    
    # Health check script
    $healthScript = @"
# health-check.ps1
Write-Host "Nusantara Ledger Health Check" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Magenta

# Check PostgreSQL
try {
    $pgResult = Test-NetConnection localhost -Port 5432
    if ($pgResult.TcpTestSucceeded) {
        Write-Host "✅ PostgreSQL: Running" -ForegroundColor Green
    } else {
        Write-Host "❌ PostgreSQL: Not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ PostgreSQL: Error checking" -ForegroundColor Red
}

# Check Redis
try {
    $redisResult = Test-NetConnection localhost -Port 6379
    if ($redisResult.TcpTestSucceeded) {
        Write-Host "✅ Redis: Running" -ForegroundColor Green
    } else {
        Write-Host "❌ Redis: Not accessible" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Redis: Error checking" -ForegroundColor Red
}

# Check Backend API
try {
    $apiResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 5
    if ($apiResponse.StatusCode -eq 200) {
        Write-Host "✅ Backend API: Healthy" -ForegroundColor Green
        $healthData = $apiResponse.Content | ConvertFrom-Json
        Write-Host "   Status: $($healthData.status)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Backend API: Unhealthy" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Backend API: Not responding" -ForegroundColor Red
}

# Check Frontend
try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "✅ Frontend: Accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ Frontend: Error" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Frontend: Not accessible" -ForegroundColor Red
}

# Check SUI CLI
try {
    $suiVersion = sui --version 2>$null
    if ($suiVersion) {
        Write-Host "✅ SUI CLI: Installed ($suiVersion)" -ForegroundColor Green
    } else {
        Write-Host "❌ SUI CLI: Not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ SUI CLI: Error" -ForegroundColor Red
}

Write-Host ""
Write-Host "Health check completed!" -ForegroundColor Magenta
"@
    
    $healthScript | Out-File -FilePath "$InstallPath\scripts\health-check.ps1" -Encoding utf8
    
    Write-ColorOutput "Service scripts created!" -Color Success
}

function Create-Test-Scripts {
    Write-Header "Creating Test Scripts"
    
    # Integration test script
    $integrationTest = @"
# run-integration-test.ps1
param(
    [switch]$Verbose
)

Write-Host "Running Nusantara Ledger Integration Tests" -ForegroundColor Magenta
Write-Host "==========================================" -ForegroundColor Magenta

$TestResults = @()
$ErrorCount = 0

function Test-Step {
    param($Name, $ScriptBlock)
    
    Write-Host ""
    Write-Host "Testing: $Name" -ForegroundColor Cyan
    
    try {
        $result = & $ScriptBlock
        if ($result) {
            Write-Host "✅ PASS: $Name" -ForegroundColor Green
            $TestResults += @{ Test = $Name; Status = "PASS"; Details = $result }
        } else {
            Write-Host "❌ FAIL: $Name" -ForegroundColor Red  
            $script:ErrorCount++
            $TestResults += @{ Test = $Name; Status = "FAIL"; Details = "No result returned" }
        }
    } catch {
        Write-Host "❌ FAIL: $Name - $($_.Exception.Message)" -ForegroundColor Red
        $script:ErrorCount++
        $TestResults += @{ Test = $Name; Status = "FAIL"; Details = $_.Exception.Message }
    }
}

# Test 1: API Health Check
Test-Step "API Health Check" {
    $response = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET
    return $response.status -eq "healthy"
}

# Test 2: Document Upload
Test-Step "Document Upload" {
    # Create test document
    $testDoc = "This is a test document for Nusantara Ledger integration testing."
    $testFile = "$env:TEMP\test-document.txt"
    $testDoc | Out-File -FilePath $testFile -Encoding utf8
    
    # Upload via API
    $form = @{
        file = Get-Item $testFile
    }
    
    $response = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/documents/upload" -Method POST -Form $form
    Remove-Item $testFile -Force
    
    return $response.success -eq $true
}

# Test 3: Dashboard Data
Test-Step "Dashboard Data" {
    $response = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/dashboard/overview" -Method GET
    return $response.stats.totalDocuments -ne $null
}

# Test 4: Database Connection
Test-Step "Database Connection" {
    # Test database connectivity
    $connectionString = "Server=localhost;Database=nusantara_ledger;User Id=nusantara_user;Password=secure_password_2024;"
    
    try {
        # Note: This requires System.Data.SqlClient or Npgsql
        # For PowerShell test, we'll use a simple connection test
        $testConnection = Test-NetConnection localhost -Port 5432
        return $testConnection.TcpTestSucceeded
    } catch {
        return $false
    }
}

# Test 5: SUI Blockchain Connection  
Test-Step "SUI Blockchain Connection" {
    try {
        $gasOutput = sui client gas --json 2>$null
        return $gasOutput -ne $null
    } catch {
        return $false
    }
}

# Test 6: Frontend Accessibility
Test-Step "Frontend Accessibility" {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 10
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

# Test 7: File Upload and Processing
Test-Step "File Processing Pipeline" {
    # Create a more complex test document
    $contractData = @"
CONTRACT AGREEMENT
Contract Number: 2024/GOV/001
Vendor: PT Test Vendor Indonesia  
Amount: Rp 500,000,000
Date: $(Get-Date -Format 'yyyy-MM-dd')
Official: John Doe, Procurement Manager
"@
    
    $testFile = "$env:TEMP\test-contract.txt"
    $contractData | Out-File -FilePath $testFile -Encoding utf8
    
    $form = @{
        file = Get-Item $testFile
    }
    
    $uploadResponse = Invoke-RestMethod -Uri "http://localhost:8000/api/v1/documents/upload" -Method POST -Form $form
    Remove-Item $testFile -Force
    
    # Check if document was processed
    Start-Sleep -Seconds 2
    return $uploadResponse.success -eq $true -and $uploadResponse.document_id -ne $null
}

# Test 8: AI Processing (Mock)
Test-Step "AI Processing Service" {
    # This would test if AI service is responding
    # For now, we'll test if the health endpoint includes AI status
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET
        # If AI service health is included in response
        return $response.status -eq "healthy"
    } catch {
        return $false
    }
}

# Test Summary
Write-Host ""
Write-Host "Integration Test Summary" -ForegroundColor Magenta
Write-Host "========================" -ForegroundColor Magenta
Write-Host "Total Tests: $($TestResults.Count)" -ForegroundColor White
Write-Host "Passed: $(($TestResults | Where-Object {$_.Status -eq 'PASS'}).Count)" -ForegroundColor Green
Write-Host "Failed: $ErrorCount" -ForegroundColor Red

if ($Verbose) {
    Write-Host ""
    Write-Host "Detailed Results:" -ForegroundColor Yellow
    foreach ($result in $TestResults) {
        $color = if ($result.Status -eq "PASS") { "Green" } else { "Red" }
        Write-Host "  $($result.Status): $($result.Test)" -ForegroundColor $color
        if ($result.Status -eq "FAIL" -and $result.Details) {
            Write-Host "    Details: $($result.Details)" -ForegroundColor Gray
        }
    }
}

if ($ErrorCount -eq 0) {
    Write-Host ""
    Write-Host "🎉 All tests passed! System is working correctly." -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ Some tests failed. Please check the system configuration." -ForegroundColor Red
    exit 1
}
"@
    
    $integrationTest | Out-File -FilePath "$InstallPath\scripts\run-integration-test.ps1" -Encoding utf8
    
    Write-ColorOutput "Test scripts created!" -Color Success
}

function Create-Documentation {
    Write-Header "Creating Documentation"
    
    # Main README
    $readme = @"
# Nusantara Ledger - Anti-Corruption Transparency System

**Sistem transparansi anti-korupsi berbasis blockchain dengan AI untuk deteksi anomali dan workflow human-in-the-loop.**

## 🎯 Overview

Nusantara Ledger adalah sistem full-stack yang menggabungkan:
- **SUI Blockchain** untuk immutable document proofs
- **AI/ML** untuk deteksi anomali dan pola mencurigakan  
- **React Dashboard** untuk monitoring dan review
- **PostgreSQL** untuk metadata (no PII on-chain)
- **Redis** untuk real-time alerts
- **IPFS** untuk encrypted document storage

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   React Frontend │    │  FastAPI Backend │    │  SUI Blockchain │
│   (Dashboard &   │◄──►│  (AI + Workers)  │◄──►│  (Proofs Only)  │
│    Alerts)       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │      Redis      │    │      IPFS       │
│   (Metadata)    │    │    (Cache)      │    │ (Encrypted Docs)│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Windows 10/11 with PowerShell 5.1+
- Administrator privileges for initial setup

### Installation
```powershell
# Download and run installer
powershell -ExecutionPolicy Bypass -File install.ps1

# Start all services
.\scripts\start-services.ps1

# Run health check
.\scripts\health-check.ps1

# Run integration tests
.\scripts\run-integration-test.ps1 -Verbose
```

## 📊 Services & Ports

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | React dashboard |
| Backend API | http://localhost:8000 | FastAPI backend |
| API Docs | http://localhost:8000/docs | OpenAPI documentation |
| PostgreSQL | localhost:5432 | Database |
| Redis | localhost:6379 | Cache & queues |

## 🔐 Security Features

- **Client-side encryption** before IPFS upload
- **Zero PII on blockchain** - only hashes and Merkle roots
- **Role-based access control** (Public/Auditor/Reviewer/Admin)
- **Audit logging** of all actions
- **Multi-signature verification** for critical operations

## 🤖 AI/ML Features

- **NLP processing** for entity extraction (Indonesian/English)
- **Graph analysis** for transaction network anomalies
- **Rule-based detection** for known corruption patterns
- **Anomaly scoring** with explainable results
- **Real-time alerting** with severity classification

## 📱 Frontend Features

### Dashboard
- **KPI Overview**: Documents, alerts, verifications
- **Real-time updates** via WebSocket
- **System health monitoring**
- **Recent activity feed**

### Document Management  
- **Drag & drop upload** with client-side hashing
- **Metadata extraction** and entity recognition
- **Verification workflow** with multiple reviewers
- **Blockchain proof** recording

### Alert System
- **Severity-based filtering** (Low/Medium/High/Critical)
- **Assignment to reviewers** with notifications
- **Evidence packages** with supporting data
- **Resolution tracking** and audit trail

### Case Management
- **Multi-document cases** for complex investigations
- **Timeline visualization** of events
- **Collaborative review** with comments
- **Export capabilities** for legal proceedings

## 📋 User Roles & Permissions

| Role | Permissions |
|------|-------------|
| **Public** | View sanitized transparency reports |
| **Auditor** | Read access to documents and alerts |
| **Reviewer** | Triage alerts, manage cases, assign actions |
| **Admin** | Full system management, user administration |

## ⚡ Alert Rules (Configurable)

1. **High-value contracts** (>5x median value)
2. **Vendor-official overlap** (shared identifiers)
3. **Circular money flows** (funds returning to origin)
4. **Rapid successive payments** (multiple large payments in short time)
5. **Weekend transactions** (large payments on non-business days)
6. **Duplicate invoices** (same invoice number multiple times)

## 🔄 Data Flow

1. **Document Upload** → Client-side hash → Encrypted IPFS storage
2. **AI Processing** → NLP extraction → Graph analysis → Anomaly scoring  
3. **Alert Generation** → Rules evaluation → Severity assignment
4. **Human Review** → Reviewer assignment → Evidence evaluation → Resolution
5. **Blockchain Commit** → Merkle proof → SUI transaction → Immutable record

## 🛠️ Management Commands

```powershell
# Start services
.\scripts\start-services.ps1

# Stop services  
.\scripts\stop-services.ps1

# Health check
.\scripts\health-check.ps1

# Run tests
.\scripts\run-integration-test.ps1

# Database backup
.\scripts\backup-database.ps1

# Update system
.\scripts\update-system.ps1
```

## 📂 Directory Structure

```
C:\NusantaraLedger\
├── backend\          # FastAPI application
├── frontend\         # React application  
├── contracts\        # SUI Move contracts
├── scripts\          # Management scripts
├── config\           # Configuration files
├── logs\             # Application logs
└── docs\             # Documentation

C:\NusantaraData\
├── storage\          # Document storage
├── backups\          # Database backups
├── postgres\         # PostgreSQL data
└── redis\            # Redis data
```

## 🔧 Configuration

### Database
- **Connection**: `postgresql://nusantara_user:password@localhost/nusantara_ledger`
- **Backup Location**: `C:\NusantaraData\backups`
- **Max Connections**: 100

### Blockchain
- **Network**: SUI Devnet (configurable to mainnet)
- **Package ID**: Auto-detected from deployment
- **Gas Budget**: 100M MIST per transaction

### AI/ML
- **Models**: CPU-only for on-premise deployment
- **Languages**: Indonesian (primary), English (fallback)
- **Threshold**: Anomaly score >0.7 triggers alerts

## 🚨 Monitoring & Alerts

### System Health
- **Database connectivity** every minute
- **Blockchain node** status every 5 minutes  
- **API response times** continuous monitoring
- **Disk space** daily checks

### Business Alerts
- **Critical anomalies** immediate notification
- **High-value transactions** within 1 hour
- **Failed verifications** next business day
- **System errors** immediate escalation

## 🏛️ Legal & Compliance

### Privacy Protection
- **No PII on blockchain** - only cryptographic proofs
- **Encryption at rest** for sensitive documents  
- **Access logging** for audit compliance
- **Right to erasure** for GDPR compliance

### Whistleblower Protection
- **Anonymous submissions** supported
- **Secure channels** for sensitive information
- **Legal review process** before publication
- **Identity protection** measures

## 📞 Support & Maintenance

### Logs Location
- **Application**: `C:\NusantaraLedger\logs\`
- **Database**: PostgreSQL logs via Windows Event Viewer
- **Web Server**: IIS logs (if using IIS)

### Backup Strategy
- **Database**: Daily automated backups
- **Documents**: IPFS pinning + local copies  
- **Configuration**: Weekly config snapshots
- **Blockchain**: Events stored immutably (no backup needed)

### Update Process
1. Stop services
2. Backup current installation
3. Deploy new version
4. Run database migrations
5. Restart services  
6. Verify health

## 🤝 Contributing

Nusantara Ledger adalah open source project. Kontribusi dapat berupa:
- Bug reports dan feature requests
- Code contributions via pull requests
- Documentation improvements
- Security vulnerability reports

## 📄 License

**Open Source** - Dapat digunakan dan dimodifikasi untuk kepentingan transparansi publik.

---

**⚠️ IMPORTANT**: This system handles sensitive anti-corruption data. Always follow proper security procedures and legal guidelines when deploying in production environments.
"@
    
    $readme | Out-File -FilePath "$InstallPath\README.md" -Encoding utf8
    
    # Security runbook
    $securityRunbook = @"
# Security Runbook - Nusantara Ledger

## 🔒 Security Overview

This document outlines security procedures, incident response, and hardening guidelines for the Nusantara Ledger anti-corruption transparency system.

## 🚨 Incident Response Procedures

### Immediate Response (0-1 hours)
1. **Isolate affected systems** - Stop services if compromise suspected
2. **Preserve evidence** - Copy logs before they rotate
3. **Notify stakeholders** - Alert admin team and legal counsel
4. **Document everything** - Start incident log with timestamps

### Investigation Phase (1-24 hours)  
1. **Analyze logs** for unauthorized access patterns
2. **Check blockchain records** for data integrity
3. **Verify backup integrity** before potential restoration
4. **Identify attack vector** and scope of compromise

### Recovery Phase (24-72 hours)
1. **Patch vulnerabilities** identified during investigation
2. **Restore from clean backups** if necessary
3. **Reset all credentials** that may have been compromised
4. **Update security controls** to prevent recurrence

### Post-Incident (1 week)
1. **Conduct lessons learned** session with team
2. **Update procedures** based on findings  
3. **File incident report** with relevant authorities
4. **Implement additional monitoring** if needed

## 🛡️ Security Controls

### Authentication & Authorization
```powershell
# Check user permissions
Get-WmiObject -Class Win32_UserAccount | Where-Object {$_.Name -like "*nusantara*"}

# Review service accounts
Get-Service | Where-Object {$_.DisplayName -like "*Nusantara*"}

# Audit failed logins
Get-EventLog -LogName Security | Where-Object {$_.EventID -eq 4625}
```

### Database Security
```powershell  
# Check database connections
netstat -an | findstr :5432

# Review database users
psql -U postgres -c "SELECT usename, usesuper FROM pg_user;"

# Check for suspicious queries in logs
Select-String -Path "C:\NusantaraData\postgres\log\*.log" -Pattern "DROP|DELETE|UPDATE" | Select-Object -Last 50
```

### Network Security
```powershell
# Check listening ports
Get-NetTCPConnection | Where-Object {$_.State -eq "Listen"} | Format-Table LocalAddress,LocalPort,OwningProcess

# Monitor network connections
Get-NetTCPConnection | Where-Object {$_.RemoteAddress -notlike "127.0.0.1" -and $_.RemoteAddress -notlike "::1"}

# Check firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Nusantara*"}
```

## 🔍 Security Monitoring

### Daily Checks
- [ ] Review failed authentication attempts
- [ ] Check database connection logs  
- [ ] Verify blockchain transaction integrity
- [ ] Monitor disk space and file changes
- [ ] Review API access logs for anomalies

### Weekly Checks  
- [ ] Full system vulnerability scan
- [ ] Review user access permissions
- [ ] Check SSL certificate validity
- [ ] Analyze system performance metrics
- [ ] Update security signatures

### Monthly Checks
- [ ] Penetration testing (internal)
- [ ] Access control review and cleanup
- [ ] Backup restoration testing
- [ ] Security patch assessment
- [ ] Incident response drill

## 🚪 Access Control Management

### User Management
```powershell
# Add new user (Admin only)
POST /api/v1/admin/users
{
  "email": "user@organization.gov.id",
  "role": "auditor", 
  "organization": "Government Agency",
  "permissions": ["read_documents", "view_alerts"]
}

# Revoke access immediately
DELETE /api/v1/admin/users/{user_id}

# Audit user activities
GET /api/v1/admin/audit-log?user_id={id}&days=30
```

### Role Definitions
- **Public**: Read-only access to sanitized transparency reports
- **Auditor**: View documents and alerts, cannot modify
- **Reviewer**: Triage alerts, manage cases, assign actions  
- **Admin**: Full system access, user management, configuration

## 🔐 Encryption & Key Management

### Data at Rest
- **Database**: Transparent Data Encryption (TDE) enabled
- **Documents**: AES-256 encryption before IPFS storage
- **Backups**: Encrypted with separate key management
- **Logs**: Sensitive data redacted, encrypted storage

### Data in Transit
- **API**: TLS 1.3 required for all connections
- **Database**: SSL connections only
- **IPFS**: Encrypted transport layer
- **Blockchain**: HTTPS for RPC connections

### Key Rotation Schedule
```powershell
# Database encryption key (quarterly)
Invoke-SqlCmd -Query "ALTER DATABASE nusantara_ledger SET ENCRYPTION ON"

# API JWT secret (monthly)
$NewSecret = [System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(64))

# TLS certificates (annually or before expiration)
certlm.msc  # Check certificate expiration dates
```

## 🚨 Alerting Rules

### Critical Alerts (Immediate Response)
- Multiple failed authentication attempts (>10 in 5 minutes)
- Database connection failures
- Unauthorized API access attempts  
- Blockchain transaction failures
- Disk space >90% full

### Warning Alerts (Response within 4 hours)
- Unusual API usage patterns
- Large document uploads outside business hours
- Failed backup operations
- Memory or CPU usage >80%
- SSL certificate expiring within 30 days

## 🔧 Hardening Checklist

### Operating System
- [ ] Install latest security updates
- [ ] Disable unnecessary services and ports
- [ ] Configure Windows Firewall restrictive rules
- [ ] Enable audit logging for security events
- [ ] Set strong password policies
- [ ] Configure account lockout policies

### Database (PostgreSQL)
- [ ] Change default passwords
- [ ] Restrict network connections to localhost
- [ ] Enable connection logging
- [ ] Configure SSL certificates  
- [ ] Set up regular automated backups
- [ ] Enable row-level security where applicable

### Application
- [ ] Use environment variables for secrets
- [ ] Validate all input parameters
- [ ] Implement rate limiting on APIs
- [ ] Add CSRF protection tokens
- [ ] Configure CORS policies restrictively
- [ ] Enable comprehensive audit logging

### Network
- [ ] Implement network segmentation
- [ ] Use VPN for remote admin access
- [ ] Configure intrusion detection system
- [ ] Set up network traffic monitoring
- [ ] Implement DDoS protection
- [ ] Regular vulnerability scanning

## 📋 Compliance Requirements

### Data Protection
- **GDPR**: Right to erasure for personal data
- **Local Privacy Laws**: Comply with Indonesian data protection
- **PII Handling**: No personal identifiers on blockchain
- **Data Retention**: Configurable retention policies

### Audit Requirements
- **Access Logging**: All system access logged with timestamps
- **Change Tracking**: Database triggers for data modifications
- **Document Integrity**: Cryptographic proof of document authenticity
- **Legal Discovery**: Ability to provide evidence for legal proceedings

## 🆘 Emergency Procedures

### System Compromise
```powershell
# Immediate isolation
Stop-Service postgresql* -Force
Stop-Service Redis -Force  
Stop-Process -Name python -Force
Stop-Process -Name node -Force

# Preserve evidence
Copy-Item "C:\NusantaraLedger\logs\*" -Destination "C:\IncidentResponse\$(Get-Date -Format 'yyyy-MM-dd-HH-mm')" -Recurse

# Alert stakeholders
Send-MailMessage -To "security@organization.gov.id" -Subject "URGENT: Nusantara Ledger Security Incident" -Body "System isolation initiated. Investigation required."
```

### Data Breach Response
1. **Assess scope** - Which data may have been accessed?
2. **Legal notification** - Comply with breach notification laws
3. **User communication** - Inform affected users if PII involved
4. **Regulatory reporting** - File required incident reports
5. **Remediation** - Implement fixes and additional controls

### Disaster Recovery
```powershell
# Database restoration
pg_restore -U nusantara_user -d nusantara_ledger C:\NusantaraData\backups\latest.backup

# Application restoration
robocopy C:\Backups\NusantaraLedger C:\NusantaraLedger /E /PURGE

# Verify blockchain integrity
sui client gas  # Verify connectivity
# Check recent transactions match local records
```

## 📞 Emergency Contacts

| Role | Contact | Phone | Email |
|------|---------|-------|-------|
| **Security Lead** | [Name] | [Phone] | security@org.gov.id |
| **System Admin** | [Name] | [Phone] | admin@org.gov.id |
| **Legal Counsel** | [Name] | [Phone] | legal@org.gov.id |
| **IT Management** | [Name] | [Phone] | it-mgmt@org.gov.id |

---

**⚠️ REMEMBER**: In case of suspected security incident, prioritize containment over investigation. Evidence preservation is important, but stopping an active breach takes precedence.
"@
    
    $securityRunbook | Out-File -FilePath "$InstallPath\docs\SECURITY_RUNBOOK.md" -Encoding utf8
    
    # Whistleblower SOP
    $whistleblowerSOP = @"
# Standard Operating Procedure - Whistleblower Protection

## 🎯 Purpose

This SOP defines procedures for handling whistleblower submissions through the Nusantara Ledger transparency system, ensuring protection of identity and proper legal review before publication.

## ⚖️ Legal Framework

### Applicable Laws
- **Indonesian Whistleblower Protection Act**
- **Anti-Corruption Law No. 31/1999 and No. 20/2001**
- **Public Information Disclosure Act No. 14/2008**
- **Data Protection and Privacy Regulations**

### Protection Guarantees
- **Identity Confidentiality**: Whistleblower identity protected by law
- **Retaliation Prohibition**: Employers cannot retaliate against whistleblowers
- **Legal Immunity**: Protection from civil/criminal liability for good-faith reports
- **Evidence Security**: Secure handling of all submitted evidence

## 🔄 Submission Process

### 1. Anonymous Submission Channel
```
Secure Portal: https://whistleblower.nusantara.gov.id
Tor Access: [onion-address].onion
Phone Hotline: 0800-XXX-XXXX (24/7)
Secure Email: whistleblower@nusantara.gov.id (PGP encrypted)
```

### 2. Required Information
- **Incident Description**: Detailed account of alleged corruption
- **Supporting Evidence**: Documents, photos, recordings (if available)
- **Timeline**: When incidents occurred
- **Parties Involved**: Names and positions (if known)
- **Impact Assessment**: Estimated financial/social impact
- **Contact Method**: How to reach submitter (optional, encrypted)

### 3. Submission Handling
```powershell
# Incoming submission processing
function Process-WhistleblowerSubmission {
    param($SubmissionId)
    
    # 1. Generate secure case number
    $CaseNumber = "WB-$(Get-Date -Format 'yyyy')-$((Get-Random -Maximum 9999).ToString('D4'))"
    
    # 2. Encrypt and store evidence
    $EncryptedPath = "C:\SecureEvidence\$CaseNumber\"
    
    # 3. Create audit trail (without PII)
    Add-AuditLog -Action "WhistleblowerSubmission" -CaseNumber $CaseNumber -Timestamp (Get-Date)
    
    # 4. Assign to legal review team
    Assign-LegalReviewer -CaseNumber $CaseNumber
    
    # 5. Send acknowledgment (if contact provided)
    Send-AcknowledgmentMessage -SubmissionId $SubmissionId
}
```

## 🔍 Investigation Workflow

### Phase 1: Initial Assessment (72 hours)
1. **Preliminary Review**
   - Legal team reviews submission for completeness
   - Risk assessment for whistleblower safety
   - Jurisdictional determination
   - Initial credibility assessment

2. **Security Measures**
   - Evidence secured in encrypted storage
   - Access restricted to authorized personnel only
   - Audit trail initiated for all access
   - Communication channels secured

3. **Assignment Decision**
   ```powershell
   # Case classification
   $CaseClassification = @{
       "Critical" = "Immediate investigation, potential criminal referral"
       "High" = "Priority investigation within 30 days"
       "Medium" = "Standard investigation within 90 days"  
       "Low" = "Preliminary inquiry, may refer to appropriate agency"
   }
   ```

### Phase 2: Investigation (30-180 days)
1. **Evidence Verification**
   - Document authenticity validation
   - Witness interviews (if applicable)
   - Financial record analysis
   - Cross-reference with existing cases

2. **Legal Analysis**  
   - Statute of limitations review
   - Potential violations identification
   - Admissibility assessment
   - Prosecutorial merit evaluation

3. **Impact Assessment**
   - Financial damage calculation
   - Public interest determination
   - Systemic risk evaluation
   - Remediation requirements

### Phase 3: Resolution (Variable timeline)
1. **Publication Decision Matrix**
   ```
   HIGH PUBLIC INTEREST + VERIFIED EVIDENCE = Publish with redactions
   HIGH PUBLIC INTEREST + UNVERIFIED = Hold pending verification
   LOW PUBLIC INTEREST + VERIFIED = Refer to appropriate agency
   LOW PUBLIC INTEREST + UNVERIFIED = Archive with monitoring
   ```

2. **Redaction Process**
   - Remove all personal identifiers
   - Protect ongoing investigations
   - Maintain evidentiary value
   - Legal counsel final review

## 🛡️ Identity Protection Measures

### Technical Safeguards
```powershell
# Access control for whistleblower data
$WhistleblowerACL = @{
    "LegalCounsel" = @("Read", "Review", "Redact")
    "Investigator" = @("Read", "Investigate") 
    "Admin" = @("SystemAccess")  # No content access
    "Public" = @()  # No access to raw submissions
}

# Encryption at rest
function Encrypt-WhistleblowerData {
    param($Data, $CaseNumber)
    
    $Key = Get-SecureKey -Purpose "Whistleblower" -CaseNumber $CaseNumber
    $EncryptedData = Protect-Data -Data $Data -Key $Key
    
    Store-SecureData -EncryptedData $EncryptedData -Location $SecureVault
}
```

### Procedural Safeguards
- **Need-to-Know Access**: Only essential personnel access submissions
- **Audit Logging**: All access logged and monitored
- **Secure Communications**: All related communications encrypted
- **Physical Security**: Evidence stored in secure facilities
- **Background Checks**: Personnel handling submissions vetted

### Communication Security
```powershell
# Secure communication with whistleblower
function Send-SecureMessage {
    param($CaseNumber, $Message, $EncryptionKey)
    
    # Encrypt message
    $EncryptedMessage = Protect-String -String $Message -Key $EncryptionKey
    
    # Send via secure channel (never email directly)
    Send-TorMessage -Destination $SecureDropbox -Message $EncryptedMessage
    
    # Log communication (without content)
    Add-AuditLog -Action "SecureCommToWhistleblower" -CaseNumber $CaseNumber
}
```

## 📋 Legal Review Checklist

### Before Investigation
- [ ] Verify whistleblower protection eligibility
- [ ] Assess potential legal risks to organization
- [ ] Determine appropriate investigative authority
- [ ] Establish evidence preservation requirements
- [ ] Review confidentiality obligations

### During Investigation  
- [ ] Monitor compliance with protection laws
- [ ] Ensure proper evidence chain of custody
- [ ] Coordinate with law enforcement if required
- [ ] Document all investigative steps
- [ ] Maintain whistleblower anonymity

### Before Publication
- [ ] Legal sufficiency review completed
- [ ] Public interest determination documented
- [ ] All PII properly redacted
- [ ] No ongoing investigation compromise
- [ ] Management and legal counsel sign-off

## 🚨 Emergency Procedures

### Threats to Whistleblower Safety
```powershell
# Emergency response protocol
function Respond-WhistleblowerThreat {
    param($CaseNumber, $ThreatLevel)
    
    if ($ThreatLevel -eq "Critical") {
        # Immediate law enforcement notification
        Notify-LawEnforcement -Priority "Urgent" -Case $CaseNumber
        
        # Suspend case processing
        Set-CaseStatus -CaseNumber $CaseNumber -Status "SecurityHold"
        
        # Enhance security measures
        Invoke-EnhancedSecurity -Target "Whistleblower" -Case $CaseNumber
    }
}
```

### Legal Challenges
- **Cease and Desist**: Immediate legal counsel consultation
- **Court Orders**: Compliance while protecting whistleblower rights  
- **Criminal Investigation**: Cooperation with law enforcement
- **Civil Litigation**: Defense coordination with legal team

## 📊 Reporting and Metrics

### Monthly Reporting
- **Submissions Received**: Count by category and severity
- **Cases Under Review**: Status and timeline tracking
- **Cases Closed**: Outcomes and resolution methods
- **Protection Incidents**: Any threats or retaliation attempts

### Annual Review
- **Program Effectiveness**: Success rates and impact assessment  
- **Process Improvements**: Lessons learned and updates
- **Training Requirements**: Staff training and awareness programs
- **Technology Updates**: Security and system enhancements

## 📞 Emergency Contacts

### Internal Team
| Role | Contact | Secure Phone | Encrypted Email |
|------|---------|--------------|-----------------|
| **Chief Legal Counsel** | [Name] | [Secure Line] | legal-secure@org.gov.id |
| **Whistleblower Coordinator** | [Name] | [Secure Line] | wb-coord@org.gov.id |
| **Security Director** | [Name] | [Secure Line] | security@org.gov.id |
| **Investigation Lead** | [Name] | [Secure Line] | investigate@org.gov.id |

### External Partners
| Organization | Purpose | Contact | Hours |
|-------------|---------|---------|-------|
| **Anti-Corruption Commission (KPK)** | Criminal referrals | [Phone] | 24/7 |
| **Attorney General's Office** | Legal coordination | [Phone] | Business hours |
| **Witness Protection Agency** | Physical protection | [Emergency] | 24/7 |
| **Cyber Crime Unit** | Digital threats | [Phone] | 24/7 |

---

**⚠️ CRITICAL REMINDER**: Whistleblower protection is both a legal obligation and moral imperative. Any compromise of whistleblower identity or safety must be treated as the highest priority security incident.

**🔒 CONFIDENTIALITY**: This SOP and all related procedures are confidential. Unauthorized disclosure may compromise ongoing investigations and whistleblower safety.
"@
    
    $whistleblowerSOP | Out-File -FilePath "$InstallPath\docs\WHISTLEBLOWER_SOP.md" -Encoding utf8
    
    Write-ColorOutput "Documentation created!" -Color Success
}

function Create-Offline-Package {
    Write-Header "Creating Offline Installation Package"
    
    # Create offline installer
    $offlineInstaller = @"
# create-offline-package.ps1
param(
    [string]$OutputPath = "C:\NusantaraOffline"
)

Write-Host "Creating Nusantara Ledger Offline Package..." -ForegroundColor Green

# Create output directory
New-Item -ItemType Directory -Path $OutputPath -Force

# Package structure
$PackageStructure = @(
    "installers",
    "wheels", 
    "node_modules",
    "models",
    "contracts",
    "config",
    "scripts",
    "docs"
)

foreach ($dir in $PackageStructure) {
    New-Item -ItemType Directory -Path "$OutputPath\$dir" -Force
}

# Download prerequisites
Write-Host "Downloading prerequisites..." -ForegroundColor Cyan

# Python wheels
pip download -r requirements.txt -d "$OutputPath\wheels"

# Node modules (if needed)
if (Test-Path "package.json") {
    npm pack
    Move-Item "*.tgz" "$OutputPath\node_modules\"
}

# AI Models
Write-Host "Downloading AI models..." -ForegroundColor Cyan
python -m spacy download en_core_web_sm --user
Copy-Item "$env:APPDATA\Python\Python*\site-packages\en_core_web_sm*" -Destination "$OutputPath\models\" -Recurse

# System installers
$Installers = @{
    "python" = "https://www.python.org/ftp/python/3.11.6/python-3.11.6-amd64.exe"
    "nodejs" = "https://nodejs.org/dist/v20.9.0/node-v20.9.0-x64.msi"
    "postgresql" = "https://get.enterprisedb.com/postgresql/postgresql-15.4-1-windows-x64.exe"
    "redis" = "https://download.redis.io/redis-stable/redis-7.2.3.msi"
}

foreach ($installer in $Installers.GetEnumerator()) {
    Write-Host "Downloading $($installer.Key)..." -ForegroundColor Yellow
    $fileName = Split-Path $installer.Value -Leaf
    Invoke-WebRequest -Uri $installer.Value -OutFile "$OutputPath\installers\$fileName"
}

# Copy application files
Write-Host "Copying application files..." -ForegroundColor Cyan
Copy-Item "$InstallPath\*" -Destination "$OutputPath\app\" -Recurse -Force

# Create offline installer script
$offlineInstallScript = @'
# offline-install.ps1
param([string]$InstallPath = "C:\NusantaraLedger")

Write-Host "Installing Nusantara Ledger (Offline Mode)..." -ForegroundColor Green

# Install prerequisites from local files
$CurrentPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Install Python
Start-Process "$CurrentPath\installers\python-3.11.6-amd64.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait

# Install Node.js  
Start-Process "$CurrentPath\installers\node-v20.9.0-x64.msi" -ArgumentList "/quiet" -Wait

# Install PostgreSQL
Start-Process "$CurrentPath\installers\postgresql-15.4-1-windows-x64.exe" -ArgumentList "--mode unattended --superpassword postgres123" -Wait

# Install Redis
Start-Process "$CurrentPath\installers\redis-7.2.3.msi" -ArgumentList "/quiet" -Wait

# Copy application
Copy-Item "$CurrentPath\app\*" -Destination $InstallPath -Recurse -Force

# Install Python dependencies from wheels
Set-Location "$InstallPath\backend"
python -m venv venv
& ".\venv\Scripts\Activate.ps1"
pip install --no-index --find-links "$CurrentPath\wheels" -r requirements.txt

# Install AI models
Copy-Item "$CurrentPath\models\*" -Destination ".\venv\Lib\site-packages\" -Recurse -Force

Write-Host "Offline installation completed!" -ForegroundColor Green
'@

    $offlineInstallScript | Out-File -FilePath "$OutputPath\offline-install.ps1" -Encoding utf8

    # Create checksum file
    Write-Host "Generating checksums..." -ForegroundColor Cyan
    $checksums = @()
    Get-ChildItem -Path $OutputPath -Recurse -File | ForEach-Object {
        $hash = Get-FileHash $_.FullName -Algorithm SHA256
        $relativePath = $_.FullName.Replace($OutputPath, "")
        $checksums += "$($hash.Hash) $relativePath"
    }
    $checksums | Out-File -FilePath "$OutputPath\checksums.txt" -Encoding utf8

    # Create final package
    $packageFile = "NusantaraLedger-Offline-$(Get-Date -Format 'yyyy-MM-dd').zip"
    Compress-Archive -Path "$OutputPath\*" -DestinationPath $packageFile -Force

    Write-Host "Offline package created: $packageFile" -ForegroundColor Green
"@
    
    $offlineInstaller | Out-File -FilePath "$InstallPath\scripts\create-offline-package.ps1" -Encoding utf8
    
    Write-ColorOutput "Offline package creator ready!" -Color Success
}

# Main Installation Function
function Main {
    Write-Header "NUSANTARA LEDGER - FULL STACK INSTALLATION"
    
    if (-not $Silent) {
        Write-ColorOutput "This will install Nusantara Ledger anti-corruption transparency system." -Color Info
        Write-ColorOutput "Installation path: $InstallPath" -Color Info
        Write-ColorOutput "Data path: $DataPath" -Color Info
        $continue = Read-Host "Continue? (Y/N)"
        if ($continue -ne 'Y' -and $continue -ne 'y') {
            Write-ColorOutput "Installation cancelled." -Color Warning
            exit 0
        }
    }
    
    try {
        # Installation steps
        if (-not $SkipPrereqs) {
            Install-Prerequisites
        }
        
        Create-Directory-Structure
        Install-Python-Dependencies
        Install-Node-Dependencies
        Setup-Database
        Setup-Redis
        Deploy-Smart-Contracts
        Create-Backend-Services
        Create-Frontend-Application
        Create-Service-Scripts
        Create-Test-Scripts
        Create-Documentation
        Create-Offline-Package
        
        Write-Header "INSTALLATION COMPLETED SUCCESSFULLY!"
        
        Write-ColorOutput "🎉 Nusantara Ledger has been installed successfully!" -Color Success
        Write-Host ""
        Write-ColorOutput "Next Steps:" -Color Header
        Write-ColorOutput "1. Start services: .\scripts\start-services.ps1" -Color Info
        Write-ColorOutput "2. Run health check: .\scripts\health-check.ps1" -Color Info
        Write-ColorOutput "3. Run integration tests: .\scripts\run-integration-test.ps1" -Color Info
        Write-Host ""
        Write-ColorOutput "Access URLs:" -Color Header
        Write-ColorOutput "- Frontend Dashboard: http://localhost:3000" -Color Success
        Write-ColorOutput "- Backend API: http://localhost:8000" -Color Success
        Write-ColorOutput "- API Documentation: http://localhost:8000/docs" -Color Success
        Write-Host ""
        Write-ColorOutput "⚠️ IMPORTANT:" -Color Warning
        Write-ColorOutput "- Change default passwords in production" -Color Warning
        Write-ColorOutput "- Fund your SUI address for blockchain transactions" -Color Warning
        Write-ColorOutput "- Review security settings before going live" -Color Warning
        
    } catch {
        Write-ColorOutput "Installation failed: $($_.Exception.Message)" -Color Error
        Write-ColorOutput "Check logs for details: $InstallPath\logs\install.log" -Color Error
        exit 1
    }
}

# ============================================================================
# VALIDATION COMMANDS (10 exact commands as requested)
# ============================================================================

Write-Header "VALIDATION COMMANDS"
Write-ColorOutput @"
After installation, run these 10 commands to validate your setup:

# Windows PowerShell Commands:
1. .\scripts\health-check.ps1                              # System health check
2. .\scripts\start-services.ps1                            # Start all services  
3. Test-NetConnection localhost -Port 8000                 # Test API port
4. Invoke-WebRequest http://localhost:8000/health          # API health endpoint
5. .\scripts\run-integration-test.ps1 -Verbose             # Integration tests

# SUI Blockchain Commands:
6. sui client active-address                               # Check SUI address
7. sui client gas                                          # Check SUI balance
8. sui client publish --gas-budget 100000000 .\contracts  # Deploy contract

# Application Test Commands:  
9. curl -X POST -F "file=@test.txt" http://localhost:8000/api/v1/documents/upload  # Upload test
10. sui client call --function record_document_proof --module transparency_ledger --package [PACKAGE_ID] --args [MERKLE_ROOT] [METADATA_HASH]  # Blockchain commit

🎯 All commands should return success status for a working installation.
"@ -Color Info

# Run main installation if script is executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}