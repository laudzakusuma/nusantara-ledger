import React, { useState, useEffect } from 'react';
import './App.css';

function Dashboard() {
  const [stats, setStats] = useState({
    documents: { total: 0, pending: 0, processed: 0 },
    alerts: { total: 0, high: 0, medium: 0, low: 0 }
  });
  const [documents, setDocuments] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [selectedFile, setSelectedFile] = useState(null);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const statsResponse = await fetch('http://localhost:8000/admin/stats');
      const statsData = await statsResponse.json();
      setStats(statsData);

      const docsResponse = await fetch('http://localhost:8000/documents');
      const docsData = await docsResponse.json();
      setDocuments(docsData);

      const alertsResponse = await fetch('http://localhost:8000/alerts');
      const alertsData = await alertsResponse.json();
      setAlerts(alertsData);

      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch data:', error);
      setLoading(false);
    }
  };

  const handleFileUpload = async (event) => {
    event.preventDefault();
    if (!selectedFile) return;

    setUploading(true);
    const formData = new FormData();
    formData.append('file', selectedFile);
    formData.append('tag', 'contract');

    try {
      const response = await fetch('http://localhost:8000/documents/upload', {
        method: 'POST',
        body: formData,
      });

      if (response.ok) {
        alert('Document uploaded successfully!');
        setSelectedFile(null);
        fetchData();
      } else {
        alert('Upload failed!');
      }
    } catch (error) {
      console.error('Upload error:', error);
      alert('Upload failed!');
    }

    setUploading(false);
  };

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'high': return '#dc2626';
      case 'medium': return '#d97706';
      case 'low': return '#2563eb';
      default: return '#6b7280';
    }
  };

  if (loading) {
    return (
      <div style={{ padding: '20px', textAlign: 'center' }}>
        <h2>🏛️ Loading Nusantara Ledger...</h2>
      </div>
    );
  }

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif', backgroundColor: '#f9fafb', minHeight: '100vh' }}>
      <header style={{ marginBottom: '30px', borderBottom: '2px solid #e5e7eb', paddingBottom: '20px' }}>
        <h1 style={{ color: '#1f2937', fontSize: '2.5rem', margin: '0' }}>
          🏛️ Nusantara Ledger
        </h1>
        <p style={{ color: '#6b7280', fontSize: '1.1rem', margin: '10px 0 0 0' }}>
          Transparency and Anti-Corruption Monitoring System
        </p>
      </header>

      {/* Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '20px', marginBottom: '30px' }}>
        <div style={{ backgroundColor: 'white', padding: '20px', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#374151' }}>📄 Documents</h3>
          <p style={{ fontSize: '2rem', margin: '0', color: '#1f2937', fontWeight: 'bold' }}>
            {stats.documents.total}
          </p>
          <p style={{ margin: '5px 0 0 0', color: '#6b7280' }}>
            {stats.documents.processed} processed, {stats.documents.pending} pending
          </p>
        </div>

        <div style={{ backgroundColor: 'white', padding: '20px', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', borderLeft: '4px solid #dc2626' }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#374151' }}>🚨 High Priority</h3>
          <p style={{ fontSize: '2rem', margin: '0', color: '#dc2626', fontWeight: 'bold' }}>
            {stats.alerts.high}
          </p>
          <p style={{ margin: '5px 0 0 0', color: '#6b7280' }}>
            Require immediate attention
          </p>
        </div>

        <div style={{ backgroundColor: 'white', padding: '20px', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', borderLeft: '4px solid #d97706' }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#374151' }}>⚠️ Medium Alerts</h3>
          <p style={{ fontSize: '2rem', margin: '0', color: '#d97706', fontWeight: 'bold' }}>
            {stats.alerts.medium}
          </p>
          <p style={{ margin: '5px 0 0 0', color: '#6b7280' }}>
            Need review
          </p>
        </div>

        <div style={{ backgroundColor: 'white', padding: '20px', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', borderLeft: '4px solid #16a34a' }}>
          <h3 style={{ margin: '0 0 10px 0', color: '#374151' }}>✅ System</h3>
          <p style={{ fontSize: '2rem', margin: '0', color: '#16a34a', fontWeight: 'bold' }}>
            Healthy
          </p>
          <p style={{ margin: '5px 0 0 0', color: '#6b7280' }}>
            All services operational
          </p>
        </div>
      </div>

      {/* Upload Section */}
      <div style={{ backgroundColor: 'white', padding: '20px', borderRadius: '8px', marginBottom: '30px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
        <h3 style={{ margin: '0 0 15px 0', color: '#374151' }}>📤 Upload Document</h3>
        <form onSubmit={handleFileUpload} style={{ display: 'flex', gap: '10px', alignItems: 'center', flexWrap: 'wrap' }}>
          <input
            type="file"
            onChange={(e) => setSelectedFile(e.target.files[0])}
            accept=".pdf,.doc,.docx,.txt,.csv"
            style={{ 
              padding: '8px 12px', 
              border: '2px solid #d1d5db', 
              borderRadius: '4px', 
              flex: '1',
              minWidth: '300px'
            }}
          />
          <button
            type="submit"
            disabled={!selectedFile || uploading}
            style={{
              padding: '10px 20px',
              backgroundColor: uploading ? '#9ca3af' : '#3b82f6',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: uploading ? 'not-allowed' : 'pointer',
              fontWeight: 'bold'
            }}
          >
            {uploading ? '⏳ Uploading...' : '📤 Upload'}
          </button>
        </form>
        <p style={{ margin: '10px 0 0 0', fontSize: '0.9rem', color: '#6b7280' }}>
          Supported: PDF, DOC, DOCX, TXT, CSV • Max 50MB
        </p>
      </div>

      {/* Content Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: window.innerWidth > 1024 ? '1fr 1fr' : '1fr', gap: '30px' }}>
        {/* Recent Documents */}
        <div>
          <h3 style={{ color: '#374151', marginBottom: '15px' }}>📋 Recent Documents</h3>
          <div style={{ backgroundColor: 'white', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
            {documents.length > 0 ? (
              documents.slice(0, 5).map((doc, index) => (
                <div
                  key={doc.id}
                  style={{
                    padding: '15px',
                    borderBottom: index < 4 ? '1px solid #f3f4f6' : 'none',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    transition: 'background-color 0.2s'
                  }}
                  onMouseOver={(e) => e.target.style.backgroundColor = '#f9fafb'}
                  onMouseOut={(e) => e.target.style.backgroundColor = 'white'}
                >
                  <div>
                    <p style={{ margin: '0', fontWeight: 'bold', color: '#1f2937' }}>
                      {doc.filename}
                    </p>
                    <p style={{ margin: '5px 0 0 0', fontSize: '0.9rem', color: '#6b7280' }}>
                      {doc.tag} • {new Date(doc.created_at).toLocaleDateString()}
                    </p>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <span
                      style={{
                        padding: '4px 8px',
                        borderRadius: '12px',
                        fontSize: '0.8rem',
                        backgroundColor: doc.status === 'processed' ? '#dcfce7' : '#fef3c7',
                        color: doc.status === 'processed' ? '#166534' : '#92400e',
                        fontWeight: 'bold'
                      }}
                    >
                      {doc.status.toUpperCase()}
                    </span>
                    {doc.anomaly_score && (
                      <p style={{ margin: '5px 0 0 0', fontSize: '0.8rem', color: doc.anomaly_score > 0.7 ? '#dc2626' : '#6b7280' }}>
                        Risk: {(doc.anomaly_score * 100).toFixed(1)}%
                      </p>
                    )}
                  </div>
                </div>
              ))
            ) : (
              <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280' }}>
                <p style={{ fontSize: '3rem', margin: '0' }}>📄</p>
                <p style={{ margin: '10px 0 0 0' }}>No documents uploaded yet</p>
                <p style={{ fontSize: '0.9rem' }}>Upload your first document to get started</p>
              </div>
            )}
          </div>
        </div>

        {/* Recent Alerts */}
        <div>
          <h3 style={{ color: '#374151', marginBottom: '15px' }}>🚨 Recent Alerts</h3>
          <div style={{ backgroundColor: 'white', borderRadius: '8px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
            {alerts.length > 0 ? (
              alerts.slice(0, 5).map((alert, index) => (
                <div
                  key={alert.id}
                  style={{
                    padding: '15px',
                    borderBottom: index < 4 ? '1px solid #f3f4f6' : 'none',
                    borderLeft: `4px solid ${getSeverityColor(alert.severity)}`
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div style={{ flex: '1' }}>
                      <p style={{ margin: '0', fontWeight: 'bold', color: '#1f2937' }}>
                        {alert.title}
                      </p>
                      <p style={{ margin: '5px 0', fontSize: '0.9rem', color: '#6b7280' }}>
                        {alert.description}
                      </p>
                      <p style={{ margin: '5px 0 0 0', fontSize: '0.8rem', color: '#6b7280' }}>
                        {new Date(alert.created_at).toLocaleDateString()}
                      </p>
                    </div>
                    <span
                      style={{
                        padding: '4px 8px',
                        borderRadius: '12px',
                        fontSize: '0.8rem',
                        backgroundColor: alert.severity === 'high' ? '#fef2f2' : alert.severity === 'medium' ? '#fffbeb' : '#dbeafe',
                        color: getSeverityColor(alert.severity),
                        fontWeight: 'bold'
                      }}
                    >
                      {alert.severity.toUpperCase()}
                    </span>
                  </div>
                </div>
              ))
            ) : (
              <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280' }}>
                <p style={{ fontSize: '3rem', margin: '0' }}>🚨</p>
                <p style={{ margin: '10px 0 0 0' }}>No alerts generated yet</p>
                <p style={{ fontSize: '0.9rem' }}>Upload documents to start analysis</p>
              </div>
            )}
          </div>
        </div>
      </div>

      <footer style={{ marginTop: '40px', paddingTop: '20px', borderTop: '1px solid #e5e7eb', textAlign: 'center', backgroundColor: 'white', borderRadius: '8px', padding: '20px' }}>
        <p style={{ color: '#6b7280', fontSize: '0.9rem', margin: '0' }}>
          Nusantara Ledger v1.0.0-dev • Open Source Transparency System
        </p>
        <p style={{ color: '#dc2626', fontSize: '0.8rem', margin: '10px 0 0 0', fontWeight: 'bold' }}>
          ⚠️ Safety Notice: Any suspected corruption case must undergo legal review before public disclosure
        </p>
      </footer>
    </div>
  );
}

function App() {
  return <Dashboard />;
}

export default App;
