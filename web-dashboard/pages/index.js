export default function Home() {
  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <h1 style={styles.title}>🏫 SGHPS</h1>
        <p style={styles.subtitle}>School ERP Platform</p>
      </div>

      <div style={styles.grid}>
        <div style={styles.card}>
          <div style={styles.icon}>👨‍🎓</div>
          <h3>Student</h3>
          <p style={styles.cardDesc}>Access your classes, homework & grades</p>
        </div>

        <div style={styles.card}>
          <div style={styles.icon}>👨‍🏫</div>
          <h3>Teacher</h3>
          <p style={styles.cardDesc}>Manage classes & student progress</p>
        </div>

        <div style={styles.card}>
          <div style={styles.icon}>👔</div>
          <h3>Principal</h3>
          <p style={styles.cardDesc}>School overview & analytics</p>
        </div>

        <div style={styles.card}>
          <div style={styles.icon}>💼</div>
          <h3>Accountant</h3>
          <p style={styles.cardDesc}>Manage fees & finances</p>
        </div>
      </div>

      <div style={styles.footer}>
        <p>© 2024 SGHPS School. All rights reserved.</p>
      </div>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '20px',
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  },
  header: {
    textAlign: 'center',
    marginBottom: '50px',
  },
  title: {
    fontSize: '48px',
    color: 'white',
    marginBottom: '10px',
  },
  subtitle: {
    fontSize: '20px',
    color: 'rgba(255,255,255,0.8)',
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
    gap: '20px',
    maxWidth: '900px',
    width: '100%',
  },
  card: {
    background: 'white',
    padding: '30px',
    borderRadius: '16px',
    textAlign: 'center',
    cursor: 'pointer',
    transition: 'transform 0.2s, box-shadow 0.2s',
    boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
  },
  icon: {
    fontSize: '48px',
    marginBottom: '10px',
  },
  cardDesc: {
    color: '#666',
    fontSize: '14px',
    marginTop: '8px',
  },
  footer: {
    marginTop: '50px',
    color: 'rgba(255,255,255,0.6)',
    fontSize: '14px',
  },
};