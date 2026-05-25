export default function AppShell({ children }: { children: React.ReactNode }) {
  return (
    <div
      style={{
        display: 'flex',
        background: '#0A0A0F',
        minHeight: '100vh',
        color: '#E8E8ED',
        fontFamily: 'Inter, sans-serif',
      }}
    >
      <aside
        style={{
          width: 240,
          background: '#1A1A2E',
          padding: 16,
          borderRight: '1px solid #00FF8833',
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        <div
          style={{
            color: '#00FF88',
            fontSize: 18,
            fontWeight: 600,
            marginBottom: 24,
            padding: '0 12px',
          }}
        >
          Legacy Vault
        </div>
        <nav style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {[
            { href: '/app', label: '🏠 Home' },
            { href: '/app/mining', label: '🎤 Soul Mining' },
            { href: '/app/guardian', label: '🛡 Guardian' },
            { href: '/app/agent', label: '🤖 Legacy Agent' },
            { href: '/app/values', label: '🧠 Value Map' },
          ].map((item) => (
            <a
              key={item.href}
              href={item.href}
              style={{
                color: '#E8E8ED',
                textDecoration: 'none',
                padding: '10px 12px',
                borderRadius: 10,
                fontSize: 14,
                transition: 'background 0.2s, color 0.2s',
                display: 'block',
              }}
              onMouseEnter={(e) => {
                ;(e.currentTarget as HTMLAnchorElement).style.background = '#1A1A2E'
                ;(e.currentTarget as HTMLAnchorElement).style.color = '#00FF88'
              }}
              onMouseLeave={(e) => {
                ;(e.currentTarget as HTMLAnchorElement).style.background = ''
                ;(e.currentTarget as HTMLAnchorElement).style.color = '#E8E8ED'
              }}
            >
              {item.label}
            </a>
          ))}
        </nav>
      </aside>
      <main style={{ flex: 1, padding: 24, overflowY: 'auto' }}>{children}</main>
    </div>
  )
}
