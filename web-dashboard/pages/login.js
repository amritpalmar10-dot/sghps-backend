import { useState } from 'react';
import Layout from '../components/Layout';

export default function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const handleLogin = (e) => {
    e.preventDefault();
    alert('Login functionality coming soon!');
  };

  return (
    <Layout>
      <div style={styles.container}>
        <div style={styles.loginBox}>
          <h2 style={styles.title}>🔐 Login to SGHPS</h2>
          
          <form onSubmit={handleLogin} style={styles.form}>
            <div style={styles.inputGroup}>
              <label style={styles.label}>Username / Email</label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                style={styles.input}
                placeholder="Enter your username"
                required
              />
            </div>

            <div style={styles.inputGroup}>
              <label style={styles.label}>Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={styles.input}
                placeholder="Enter your password"
                required
              />
            </div>

            <button type="submit" style={styles.button}>
              Login
            </button>
          </form>

          <div style={styles.help}>
            <a href="#" style={styles.link}>Forgot Password?</a>
            <span style={styles.separator}>|</span>
            <a href="/" style={styles.link}>Back to Home</a>
          </div>
        </div>
      </div>
    </Layout>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    padding: '20px',
  },
  loginBox: {
    background: 'white',
    padding: '40px',
    borderRadius: '16px',
    boxShadow: '0 10px 40px rgba(0,0,0,0.2)',
    width: '100%',
    maxWidth: '400px',
  },
  title: {
    textAlign: 'center',
    marginBottom: '30px',
    color: '#333',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px',
  },
  inputGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '5px',
  },
  label: {
    color: '#555',
    fontSize: '14px',
    fontWeight: '500',
  },
  input: {
    padding: '12px',
    border: '1px solid #ddd',
    borderRadius: '8px',
    fontSize: '16px',
    outline: 'none',
  },
  button: {
    padding: '14px',
    background: '#4a6cf7',
    color: 'white',
    border: 'none',
    borderRadius: '8px',
    fontSize: '16px',
    fontWeight: '600',
    cursor: 'pointer',
  },
  help: {
    textAlign: 'center',
    marginTop: '20px',
  },
  link: {
    color: '#4a6cf7',
    textDecoration: 'none',
    fontSize: '14px',
  },
  separator: {
    margin: '0 10px',
    color: '#ccc',
  },
};