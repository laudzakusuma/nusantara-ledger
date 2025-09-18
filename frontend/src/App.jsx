import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
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
      <div style={{ 
        padding: '40px', 
        textAlign: 'center', 
        fontFamily: 'Arial, sans-serif',
        backgroundColor: '#f9fafb',
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }}>
        <div>
          <div style={{ fontSize: '4rem', marginBottom: '20px' }}>🏛️</div>
          <h2 style={{ color: '#1f2937', margin: '0' }}>Loading Nusantara Ledger...</h2>
          <p style={{ color: '#6b7280' }}>Connecting to backend services...</p>
        </div>
      </div>
    );
  }

  return (
    <div style={{ 
      fontFamily: 'Arial, sans-serif', 
      backgroundColor: '#f9fafb', 
      minHeight: '100vh',
      padding: '0'
    }}>
      {/* Header */}
      <header style={{ 
        backgroundColor: 'white',
        borderBottom: '1px solid #e5e7eb',
        padding: '20px 40px',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)'
      }}>
        <h1 style={{ 
          color: '#1f2937', 
          fontSize: '2.5rem', 
          margin: '0',
          display: 'flex',
          alignItems: 'center',
          gap: '15px'
        }}>
          <span>🏛️</span>
          Nusantara Ledger
        </h1>
        <p style={{ 
          color: '#6b7280', 
          fontSize: '1.1rem', 
          margin: '10px 0 0 0' 
        }}>
          Transparency and Anti-Corruption Monitoring System
        </p>
      </header>

      <div style={{ padding: '40px' }}>
        {/* Stats Cards */}
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', 
          gap: '20px', 
          marginBottom: '40px' 
        }}>
          <div style={{ 
            backgroundColor: 'white', 
            padding: '30px', 
            borderRadius: '12px', 
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            border: '1px solid #e5e7eb'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
              <div style={{ fontSize: '2rem' }}>📄</div>
              <div>
                <h3 style={{ margin: '0 0 5px 0', color: '#374151', fontSize: '1.1rem' }}>
                  Total Documents
                </h3>
                <p style={{ 
                  fontSize: '2.5rem', 
                  margin: '0', 
                  color: '#1f2937', 
                  fontWeight: 'bold' 
                }}>
                  {stats.documents.total}
                </p>
                <p style={{ margin: '10px 0 0 0', color: '#6b7280', fontSize: '0.9rem' }}>
                  {stats.documents.processed} processed • {stats.documents.pending} pending
                </p>
              </div>
            </div>
          </div>

          <div style={{ 
            backgroundColor: 'white', 
            padding: '30px', 
            borderRadius: '12px', 
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            border: '1px solid #e5e7eb',
            borderLeft: '4px solid #dc2626'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
              <div style={{ fontSize: '2rem' }}>🚨</div>
              <div>
                <h3 style={{ margin: '0 0 5px 0', color: '#374151', fontSize: '1.1rem' }}>
                  High Priority Alerts
                </h3>
                <p style={{ 
                  fontSize: '2.5rem', 
                  margin: '0', 
                  color: '#dc2626', 
                  fontWeight: 'bold' 
                }}>
                  {stats.alerts.high}
                </p>
                <p style={{ margin: '10px 0 0 0', color: '#6b7280', fontSize: '0.9rem' }}>
                  Require immediate attention
                </p>
              </div>
            </div>
          </div>

          <div style={{ 
            backgroundColor: 'white', 
            padding: '30px', 
            borderRadius: '12px', 
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            border: '1px solid #e5e7eb',
            borderLeft: '4px solid #d97706'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
              <div style={{ fontSize: '2rem' }}>⚠️</div>
              <div>
                <h3 style={{ margin: '0 0 5px 0', color: '#374151', fontSize: '1.1rem' }}>
                  Medium Alerts
                </h3>
                <p style={{ 
                  fontSize: '2.5rem', 
                  margin: '0', 
                  color: '#d97706', 
                  fontWeight: 'bold' 
                }}>
                  {stats.alerts.medium}
                </p>
                <p style={{ margin: '10px 0 0 0', color: '#6b7280', fontSize: '0.9rem' }}>
                  Need review
                </p>
              </div>
            </div>
          </div>

          <div style={{ 
            backgroundColor: 'white', 
            padding: '30px', 
            borderRadius: '12px', 
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
            border: '1px solid #e5e7eb',
            borderLeft: '4px solid #16a34a'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
              <div style={{ fontSize: '2rem' }}>✅</div>
              <div>
                <h3 style={{ margin: '0 0 5px 0', color: '#374151', fontSize: '1.1rem' }}>
                  System Status
                </h3>
                <p style={{ 
                  fontSize: '2.5rem', 
                  margin: '0', 
                  color: '#16a34a', 
                  fontWeight: 'bold' 
                }}>
                  Healthy
                </p>
                <p style={{ margin: '10px 0 0 0', color: '#6b7280', fontSize: '0.9rem' }}>
                  All services operational
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Upload Section */}
        <div style={{ 
          backgroundColor: 'white', 
          padding: '30px', 
          borderRadius: '12px', 
          marginBottom: '40px', 
          boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
          border: '1px solid #e5e7eb'
        }}>
          <h3 style={{ 
            margin: '0 0 20px 0', 
            color: '#374151', 
            display: 'flex', 
            alignItems: 'center', 
            gap: '10px',
            fontSize: '1.3rem'
          }}>
            <span>📤</span> Upload Document
          </h3>
          <form onSubmit={handleFileUpload} style={{ 
            display: 'flex', 
            gap: '15px', 
            alignItems: 'center', 
            flexWrap: 'wrap' 
          }}>
            <input
              type="file"
              onChange={(e) => setSelectedFile(e.target.files[0])}
              accept=".pdf,.doc,.docx,.txt,.csv"
              style={{ 
                padding: '12px 15px', 
                border: '2px solid #d1d5db', 
                borderRadius: '8px', 
                flex: '1',
                minWidth: '300px',
                fontSize: '1rem'
              }}
            />
            <button
              type="submit"
              disabled={!selectedFile || uploading}
              style={{
                padding: '12px 24px',
                backgroundColor: uploading ? '#9ca3af' : '#3b82f6',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                cursor: uploading ? 'not-allowed' : 'pointer',
                fontWeight: 'bold',
                fontSize: '1rem',
                transition: 'all 0.2s'
              }}
            >
              {uploading ? '⏳ Uploading...' : '📤 Upload'}
            </button>
          </form>
          <p style={{ 
            margin: '15px 0 0 0', 
            fontSize: '0.9rem', 
            color: '#6b7280' 
          }}>
            Supported formats: PDF, DOC, DOCX, TXT, CSV • Maximum 50MB
          </p>
        </div>

        {/* Content Grid */}
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: window.innerWidth > 1024 ? '1fr 1fr' : '1fr', 
          gap: '40px' 
        }}>
          {/* Recent Documents */}
          <div>
            <h3 style={{ 
              color: '#374151', 
              marginBottom: '20px',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              fontSize: '1.3rem'
            }}>
              <span>📋</span> Recent Documents
            </h3>
            <div style={{ 
              backgroundColor: 'white', 
              borderRadius: '12px', 
              boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
              border: '1px solid #e5e7eb',
              overflow: 'hidden'
            }}>
              {documents.length > 0 ? (
                documents.slice(0, 5).map((doc, index) => (
                  <div
                    key={doc.id}
                    style={{
                      padding: '20px',
                      borderBottom: index < 4 ? '1px solid #f3f4f6' : 'none',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      transition: 'background-color 0.2s'
                    }}
                  >
                    <div>
                      <p style={{ 
                        margin: '0 0 8px 0', 
                        fontWeight: 'bold', 
                        color: '#1f2937',
                        fontSize: '1rem'
                      }}>
                        {doc.filename}
                      </p>
                      <p style={{ 
                        margin: '0', 
                        fontSize: '0.9rem', 
                        color: '#6b7280' 
                      }}>
                        {doc.tag} • {new Date(doc.created_at).toLocaleDateString()}
                      </p>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <span
                        style={{
                          padding: '6px 12px',
                          borderRadius: '16px',
                          fontSize: '0.8rem',
                          backgroundColor: doc.status === 'processed' ? '#dcfce7' : '#fef3c7',
                          color: doc.status === 'processed' ? '#166534' : '#92400e',
                          fontWeight: 'bold',
                          textTransform: 'uppercase'
                        }}
                      >
                        {doc.status}
                      </span>
                      {doc.anomaly_score && (
                        <p style={{ 
                          margin: '8px 0 0 0', 
                          fontSize: '0.8rem', 
                          color: doc.anomaly_score > 0.7 ? '#dc2626' : '#6b7280',
                          fontWeight: doc.anomaly_score > 0.7 ? 'bold' : 'normal'
                        }}>
                          Risk: {(doc.anomaly_score * 100).toFixed(1)}%
                        </p>
                      )}
                    </div>
                  </div>
                ))
              ) : (
                <div style={{ 
                  padding: '60px', 
                  textAlign: 'center', 
                  color: '#6b7280' 
                }}>
                  <div style={{ fontSize: '4rem', marginBottom: '20px' }}>📄</div>
                  <h4 style={{ margin: '0 0 10px 0', color: '#374151' }}>
                    No documents uploaded yet
                  </h4>
                  <p style={{ margin: '0', fontSize: '0.9rem' }}>
                    Upload your first document to get started
                  </p>
                </div>
              )}
            </div>
          </div>

          {/* Recent Alerts */}
          <div>
            <h3 style={{ 
              color: '#374151', 
              marginBottom: '20px',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              fontSize: '1.3rem'
            }}>
              <span>🚨</span> Recent Alerts
            </h3>
            <div style={{ 
              backgroundColor: 'white', 
              borderRadius: '12px', 
              boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
              border: '1px solid #e5e7eb',
              overflow: 'hidden'
            }}>
              {alerts.length > 0 ? (
                alerts.slice(0, 5).map((alert, index) => (
                  <div
                    key={alert.id}
                    style={{
                      padding: '20px',
                      borderBottom: index < 4 ? '1px solid #f3f4f6' : 'none',
                      borderLeft: `4px solid ${getSeverityColor(alert.severity)}`
                    }}
                  >
                    <div style={{ 
                      display: 'flex', 
                      justifyContent: 'space-between', 
                      alignItems: 'flex-start',
                      gap: '15px'
                    }}>
                      <div style={{ flex: '1' }}>
                        <p style={{ 
                          margin: '0 0 8px 0', 
                          fontWeight: 'bold', 
                          color: '#1f2937',
                          fontSize: '1rem'
                        }}>
                          {alert.title}
                        </p>
                        <p style={{ 
                          margin: '0 0 8px 0', 
                          fontSize: '0.9rem', 
                          color: '#6b7280',
                          lineHeight: '1.4'
                        }}>
                          {alert.description}
                        </p>
                        <p style={{ 
                          margin: '0', 
                          fontSize: '0.8rem', 
                          color: '#9ca3af' 
                        }}>
                          {new Date(alert.created_at).toLocaleDateString()}
                        </p>
                      </div>
                      <span
                        style={{
                          padding: '6px 12px',
                          borderRadius: '16px',
                          fontSize: '0.8rem',
                          backgroundColor: alert.severity === 'high' ? '#fef2f2' : 
                                            alert.severity === 'medium' ? '#fffbeb' : '#dbeafe',
                          color: getSeverityColor(alert.severity),
                          fontWeight: 'bold',
                          textTransform: 'uppercase',
                          whiteSpace: 'nowrap'
                        }}
                      >
                        {alert.severity}
                      </span>
                    </div>
                  </div>
                ))
              ) : (
                <div style={{ 
                  padding: '60px', 
                  textAlign: 'center', 
                  color: '#6b7280' 
                }}>
                  <div style={{ fontSize: '4rem', marginBottom: '20px' }}>🚨</div>
                  <h4 style={{ margin: '0 0 10px 0', color: '#374151' }}>
                    No alerts generated yet
                  </h4>
                  <p style={{ margin: '0', fontSize: '0.9rem' }}>
                    Upload documents to start analysis
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer style={{ 
        marginTop: '60px', 
        paddingTop: '40px', 
        paddingBottom: '40px',
        paddingLeft: '40px',
        paddingRight: '40px',
        borderTop: '1px solid #e5e7eb', 
        textAlign: 'center',
        backgroundColor: 'white'
      }}>
        <p style={{ 
          color: '#6b7280', 
          fontSize: '0.9rem', 
          margin: '0 0 10px 0' 
        }}>
          Nusantara Ledger v1.0.0-dev • Open Source Transparency System
        </p>
        <div style={{
          backgroundColor: '#fef3c7',
          border: '1px solid #f59e0b',
          borderRadius: '8px',
          padding: '15px',
          maxWidth: '600px',
          margin: '0 auto'
        }}>
          <p style={{ 
            color: '#92400e', 
            fontSize: '0.9rem', 
            margin: '0',
            fontWeight: 'bold'
          }}>
            ⚠️ Safety Notice: Any suspected corruption case must undergo legal review before public disclosure
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;