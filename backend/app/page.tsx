export default function Home() {
  return (
    <main style={{ fontFamily: 'system-ui, sans-serif', padding: 32, maxWidth: 640 }}>
      <h1>Lumma Agendamentos — Backend</h1>
      <p>API de agendamento do Espaço Lumma. Endpoints sob <code>/api/booking/*</code>.</p>
      <p>Health check: <code>/api/health</code></p>
    </main>
  );
}
