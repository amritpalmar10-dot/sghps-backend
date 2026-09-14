export default function Layout({ children }) {
  return (
    <div style={styles.layout}>
      <main style={styles.main}>
        {children}
      </main>
    </div>
  );
}

const styles = {
  layout: {
    minHeight: '100vh',
    display: 'flex',
    flexDirection: 'column',
  },
  main: {
    flex: 1,
  },
};