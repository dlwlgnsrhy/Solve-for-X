import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Solve-for-X | The Tech of Human Dignity",
  description: "Solve-for-X Official Corporate Website by soluni. Building automated ecosystems to buy back human time and establish digital legacy.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.variable} antialiased`}>
        {/* 기업형 글로벌 내비게이션 바 */}
        <nav className="global-nav">
          <div className="nav-container">
            <div className="nav-logo">
              Solve-for-X 
              <span style={{ fontSize: '0.75rem', fontWeight: 500, color: 'var(--gray)', marginLeft: '0.4rem', letterSpacing: '0' }}>by soluni</span>
            </div>
            <div className="nav-links">
              <a href="#vision">Vision</a>
              <a href="#ecosystem">Products</a>
              <a href="#principles">Principles</a>
            </div>
          </div>
        </nav>
        
        {children}
        
        {/* 기업형 풋터 */}
        <footer className="global-footer">
          <div className="footer-container">
            <p>© 2026 soluni. All rights reserved.</p>
            <div className="footer-links">
              <a href="mailto:hello@soluni.com">Contact</a>
              <a href="https://github.com/dlwlgnsrhy" target="_blank" rel="noopener noreferrer">GitHub</a>
            </div>
          </div>
        </footer>
      </body>
    </html>
  );
}
