'use client';

import React, { useState } from 'react';

export default function SupportPage() {
  const [appId, setAppId] = useState('sfx_memento_mori');
  const [email, setEmail] = useState('');
  const [subject, setSubject] = useState('');
  const [content, setContent] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  // Dynamic FAQ pre-screening simulation as user types
  const getFAQRecommendations = () => {
    if (content.toLowerCase().includes('payment') || content.toLowerCase().includes('결제')) {
      return [
        { q: "결제 완료 후 Memento Mori 그리드 해금이 안 됩니다.", a: "인앱 결제 토큰 검증 지연 시, 설정 > 동기화 버튼을 눌러 Vega System과 강제 동기화해 주십시오." },
        { q: "구독 영수증 및 환불 규정이 궁금합니다.", a: "각 스토어(애플/구글)의 결제 내역에서 48시간 이내에 직접 즉시 환불을 청구하실 수 있습니다." }
      ];
    }
    if (content.toLowerCase().includes('signature') || content.toLowerCase().includes('서명')) {
      return [
        { q: "Imjong Care 서명 SVG 파일이 깨져 보입니다.", a: "사용 중이신 브라우저의 캔버스 렌더러 가속이 활성화되어 있는지 확인해 주십시오." }
      ];
    }
    return [
      { q: "Solve-for-X SSO 통합 계정이란 무엇인가요?", a: "하나의 계정으로 Memento Mori, Imjong Care, Moon Whisper 등 생태계의 모든 앱을 통합 사용할 수 있는 시스템입니다." },
      { q: "데이터가 유실될 위험은 없나요?", a: "모든 Will 및 라이프 로그 정보는 군용 등급(AES-256)으로 암호화되어 분산 복제 보관됩니다." }
    ];
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setTimeout(() => {
      setIsSubmitting(false);
      setSubmitted(true);
    }, 1500);
  };

  return (
    <main style={{ marginTop: '80px', minHeight: '80vh', padding: '3rem 2rem', maxWidth: '1200px', margin: '80px auto 0 auto' }}>
      <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '3rem' }}>
        
        {/* Left Hand: Glassmorphic CS Ticket Form */}
        <div style={{
          background: 'var(--card-bg)',
          border: '1px solid var(--card-border)',
          borderRadius: '12px',
          padding: '2.5rem',
          boxShadow: '0 8px 32px 0 rgba(0, 0, 0, 0.08)'
        }}>
          <h1 style={{ fontSize: '2rem', fontWeight: 800, letterSpacing: '-0.04em', marginBottom: '0.5rem' }}>
            Solve-for-X Support Center
          </h1>
          <p style={{ color: 'var(--gray)', fontSize: '0.95rem', marginBottom: '2rem' }}>
            생태계 앱들의 모든 불편 및 건의사항을 접수해 주십시오. 1시간 배치 수집 후 즉각 SRE 엔진이 대응합니다.
          </p>

          {submitted ? (
            <div style={{ textAlign: 'center', padding: '3rem 0' }}>
              <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>✅</div>
              <h2 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.5rem' }}>문의 사항 접수 완료</h2>
              <p style={{ color: 'var(--gray)', fontSize: '0.95rem', marginBottom: '2rem' }}>
                지훈님의 최종 승인 하에 1시간 내로 {email} 메일 또는 스토어 답변으로 공식 피드백이 전송됩니다.
              </p>
              <button 
                onClick={() => { setSubmitted(false); setContent(''); setSubject(''); }}
                style={{
                  background: 'var(--accent)',
                  color: 'var(--background)',
                  border: 'none',
                  padding: '0.75rem 1.5rem',
                  borderRadius: '6px',
                  fontWeight: 600,
                  cursor: 'pointer'
                }}
              >
                추가 문의 작성
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <div>
                <label style={{ display: 'block', fontWeight: 600, marginBottom: '0.5rem', fontSize: '0.9rem' }}>대상 애플리케이션</label>
                <select 
                  value={appId} 
                  onChange={(e) => setAppId(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '0.75rem',
                    borderRadius: '6px',
                    border: '1px solid var(--card-border)',
                    background: 'var(--background)',
                    color: 'var(--foreground)',
                    outline: 'none'
                  }}
                >
                  <option value="sfx_memento_mori">SFX Memento Mori (인생 격자)</option>
                  <option value="sfx_imjong_care">SFX Imjong Care (유서 금고)</option>
                  <option value="moon_whisper">Moon Whisper (감성 일기)</option>
                  <option value="sfx_core">SSO 및 계정 통합 관리</option>
                </select>
              </div>

              <div>
                <label style={{ display: 'block', fontWeight: 600, marginBottom: '0.5rem', fontSize: '0.9rem' }}>이메일 주소</label>
                <input 
                  type="email" 
                  required
                  placeholder="name@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '0.75rem',
                    borderRadius: '6px',
                    border: '1px solid var(--card-border)',
                    background: 'var(--background)',
                    color: 'var(--foreground)',
                    outline: 'none'
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontWeight: 600, marginBottom: '0.5rem', fontSize: '0.9rem' }}>제목</label>
                <input 
                  type="text" 
                  required
                  placeholder="문의의 핵심 요약을 적어주세요."
                  value={subject}
                  onChange={(e) => setSubject(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '0.75rem',
                    borderRadius: '6px',
                    border: '1px solid var(--card-border)',
                    background: 'var(--background)',
                    color: 'var(--foreground)',
                    outline: 'none'
                  }}
                />
              </div>

              <div>
                <label style={{ display: 'block', fontWeight: 600, marginBottom: '0.5rem', fontSize: '0.9rem' }}>상세 문의 내용</label>
                <textarea 
                  required
                  rows={6}
                  placeholder="버그나 기능 질문을 자유롭게 적어주세요. 타이핑하는 순간 우측에 AI 해결 가이드가 활성화됩니다."
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  style={{
                    width: '100%',
                    padding: '0.75rem',
                    borderRadius: '6px',
                    border: '1px solid var(--card-border)',
                    background: 'var(--background)',
                    color: 'var(--foreground)',
                    outline: 'none',
                    resize: 'vertical'
                  }}
                />
              </div>

              <button 
                type="submit" 
                disabled={isSubmitting}
                style={{
                  background: 'var(--accent)',
                  color: 'var(--background)',
                  border: 'none',
                  padding: '1rem',
                  borderRadius: '6px',
                  fontWeight: 700,
                  cursor: 'pointer',
                  fontSize: '1rem',
                  opacity: isSubmitting ? 0.7 : 1,
                  transition: 'opacity 0.2s ease'
                }}
              >
                {isSubmitting ? 'Vega System에 주입 중...' : '지원 티켓 제출'}
              </button>
            </form>
          )}
        </div>

        {/* Right Hand: AI Deflection FAQs Panel */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2.5rem' }}>
          <div style={{
            background: 'var(--card-bg)',
            border: '1px solid var(--card-border)',
            borderRadius: '12px',
            padding: '2rem',
            boxShadow: '0 8px 32px 0 rgba(0, 0, 0, 0.04)'
          }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 700, marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span>🤖</span> AI 실시간 최적 솔루션 매칭
            </h3>
            <p style={{ fontSize: '0.85rem', color: 'var(--gray)', marginBottom: '1.5rem' }}>
              지훈님의 운영 리소스를 아끼기 위해 입력 중인 내용을 기기 학습하여 FAQ 솔루션을 즉각 렌더링합니다.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {getFAQRecommendations().map((faq, idx) => (
                <div key={idx} style={{
                  padding: '1rem',
                  borderRadius: '8px',
                  background: 'var(--background)',
                  borderLeft: '4px solid #00FF66'
                }}>
                  <div style={{ fontWeight: 600, fontSize: '0.9rem', marginBottom: '0.4rem' }}>Q. {faq.q}</div>
                  <div style={{ fontSize: '0.85rem', color: 'var(--gray)' }}>A. {faq.a}</div>
                </div>
              ))}
            </div>
          </div>

          <div style={{
            background: 'linear-gradient(135deg, rgba(0, 255, 102, 0.05) 0%, rgba(0, 240, 255, 0.05) 100%)',
            border: '1px solid rgba(0, 255, 102, 0.2)',
            borderRadius: '12px',
            padding: '2rem',
          }}>
            <h4 style={{ fontSize: '1rem', fontWeight: 700, color: 'var(--accent)', marginBottom: '0.5rem' }}>SRE Operational Status</h4>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem', color: 'var(--gray)' }}>
              <span style={{ display: 'inline-block', width: '8px', height: '8px', borderRadius: '50%', background: '#00FF66', boxShadow: '0 0 8px #00FF66' }}></span>
              All services operational (Next.js & Flutter OK)
            </div>
          </div>
        </div>

      </div>
    </main>
  );
}
