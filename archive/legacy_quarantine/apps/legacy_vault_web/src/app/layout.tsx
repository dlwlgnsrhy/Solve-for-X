export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body
        style={{
          margin: 0,
          background: '#0A0A0F',
          color: '#E8E8ED',
          minHeight: '100vh',
        }}
      >
        {children}
      </body>
    </html>
  )
}
