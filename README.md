# Nusantara Ledger

A zero-cost, on-premise capable transparency and anti-corruption system combining SUI blockchain + AI for suspicious fund flow detection.

## Quick Start

1. **Copy environment file:**
   ```powershell
   cp .env.example .env
   ```

2. **Install Python dependencies:**
   ```powershell
   cd backend
   pip install -r requirements.txt
   ```

3. **Install Node.js dependencies:**
   ```powershell
   cd frontend
   npm install
   ```

4. **Start the backend:**
   ```powershell
   cd backend
   python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

5. **Start the frontend (new terminal):**
   ```powershell
   cd frontend
   npm run dev
   ```

6. **Access the application:**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000/docs

## Default Credentials

- Username: dmin
- Password: dmin

**?? Change these immediately in production!**

## Next Steps

1. Configure your .env file with proper settings
2. Set up SUI wallet and get devnet SUI for testing
3. Deploy the SUI contract: cd contracts && sui client publish
4. Upload test documents and verify the system works

## Documentation

See the docs/ directory for detailed documentation and runbooks.

## Safety Notice

?? **CRITICAL**: Any suspected corruption case must be escalated following the whistleblower SOP and undergo legal review before public disclosure.
