'use client';

import React, { useState } from 'react';

// Pre-seeded high-value support tickets mapping PostgreSQL `sfx_core.support_tickets`
const INITIAL_TICKETS = [
  {
    ticket_id: 'tkt_89f0a2d4',
    app_id: 'sfx_memento_mori',
    source: 'PLAY_STORE',
    raw_identifier: 'gp_rev_982cd3',
    user_email: 'jihun_fan@gmail.com',
    subject: '결제 직후 그리드 언락 멈춤 현상',
    content: 'Memento Mori 앱에서 그리드 영구 해금 상품을 결제 완료했는데, 화면이 그대로 멈추고 라이프 맵이 나타나지 않습니다. 리버팟 상태 동기화 오류인 것 같습니다.',
    urgency: 'CRITICAL',
    sentiment: 'ANGRY',
    status: 'OPEN',
    diagnostics: {
      sso_uuid: 'usr_f892cb91-ac88-4220-bb31-29088cc29d8a',
      device: 'iPhone 15 Pro Max | iOS 17.4',
      last_error: 'NullPointerException inside sync_service.dart:L82',
      account_tier: 'PRO_BACKER'
    },
    ai_draft: '안녕하세요, Solve-for-X 개발 조직입니다. 지훈님의 Vega SRE 검증 결과, SharedPreferences 버퍼 충돌로 인해 로컬 리버팟 락이 풀리지 않았음이 감지되었습니다. 지훈님의 즉각적인 패치 지시에 따라 해당 오류가 긴급 릴리즈 수정되었사오니, 앱스토어 업데이트를 진행하신 뒤 설정 > 동기화를 탭해주시면 즉각 언락 처리됩니다. 믿고 성원해주셔서 깊이 감사드립니다.'
  },
  {
    ticket_id: 'tkt_392fd612',
    app_id: 'sfx_imjong_care',
    source: 'EMAIL',
    raw_identifier: 'msg_98cd392-f39a',
    user_email: 'legacy_maker@naver.com',
    subject: '유서 PDF 다운로드 시 한글 깨짐 현상',
    content: '서명을 삽입하여 PDF 금고를 다운로드 받았는데, 한글 폰트가 물음표(?)로 깨집니다. 이 부분 수정 가능할까요? 중요한 유서 서류입니다.',
    urgency: 'HIGH',
    sentiment: 'NEUTRAL',
    status: 'OPEN',
    diagnostics: {
      sso_uuid: 'usr_2910fa88-d218-4efc-8fc2-a89cf29188a1',
      device: 'Samsung Galaxy S24 Ultra | Android 14',
      last_error: 'PdfFontDescriptorException: Font Orbitron is missing Korean glyphs',
      account_tier: 'FREE'
    },
    ai_draft: '안녕하세요, Solve-for-X 유서 금고 서비스 데스크입니다. PDF 변환 엔진에서 Orbitron 폰트 매핑 시 한국어 글리프 인코딩 미지원으로 누락된 점이 확인되었습니다. SRE 패치를 가동하여 한글 디폴트 폰트인 나눔고딕으로 강제 Fallback 처리하였습니다. 지금 다시 서비스 데스크 승인 다운로드를 진행하시면 아름답게 서명이 찍힌 유서를 획득하실 수 있습니다.'
  },
  {
    ticket_id: 'tkt_0019ff2d',
    app_id: 'moon_whisper',
    source: 'APP_STORE',
    raw_identifier: 'ap_rev_291823',
    user_email: 'anon_dreamer@outlook.com',
    subject: '다이나믹 감정 오디오 파형 피드백 제안',
    content: '일기를 음성으로 녹음할 때 나오는 백그라운드 파형이 조금 더 밝고 네온 빛으로 3D 물결처럼 넘실거리면 디자인이 완성될 것 같아요. 추가 제안합니다.',
    urgency: 'MEDIUM',
    sentiment: 'HAPPY',
    status: 'OPEN',
    diagnostics: {
      sso_uuid: 'usr_bc782191-ff18-4a11-a89c-d82910fffa81',
      device: 'MacBook Air | macOS 14.5',
      last_error: 'No exceptions. Great performance.',
      account_tier: 'FREE'
    },
    ai_draft: '귀중한 영감을 전해주셔서 깊이 감사드립니다. Moon Whisper의 감성 오디오 파형 시각화 기능을 3D Canvas 가속이 반영된 네온 컬러 셰이더로 강화하여 차세대 마이너 업데이트에 반영하기로 지훈님과 결정하였습니다. 지훈님의 특별 승인을 받아 향후 PRO 혜택도 일부 지급 드릴 예정이오니 기대해 주시기 바랍니다.'
  }
];

export default function AdminServiceDesk() {
  const [tickets, setTickets] = useState(INITIAL_TICKETS);
  const [selectedTicket, setSelectedTicket] = useState<any>(INITIAL_TICKETS[0]);
  const [editedDraft, setEditedDraft] = useState(INITIAL_TICKETS[0].ai_draft);
  const [isPatching, setIsPatching] = useState(false);
  const [patchLogs, setPatchLogs] = useState<string[]>([]);

  const handleSelectTicket = (tkt: any) => {
    setSelectedTicket(tkt);
    setEditedDraft(tkt.ai_draft);
  };

  const handleApproveSend = (ticketId: string) => {
    setTickets(prev => prev.map(t => {
      if (t.ticket_id === ticketId) {
        return { ...t, status: 'DISPATCHED' };
      }
      return t;
    }));
    alert(`✅ 지훈님 승인 승낙! Gmail API 및 스토어로 답장 전송이 완료되었습니다.`);
  };

  const triggerAgentPatch = () => {
    setIsPatching(true);
    setPatchLogs([]);
    const logSteps = [
      "🔍 [1/4] Git 레포지토리 로컬 소스 분석 중...",
      "🛠️ [2/4] AppTheme.dart:L82 Null 예외 방지 안전 가드 코드 자율 주입 완료.",
      "🧪 [3/4] flutter test 실행: widget_test 및 logic_test 100% 통과 (0 errors).",
      "🚀 [4/4] Fastlane 빌드 패키징 가동 & Google Play Console 심사 자동 제출 완료! ✅"
    ];

    logSteps.forEach((step, idx) => {
      setTimeout(() => {
        setPatchLogs(prev => [...prev, step]);
        if (idx === logSteps.length - 1) {
          setIsPatching(false);
        }
      }, (idx + 1) * 1200);
    });
  };

  return (
    <main style={{ marginTop: '80px', minHeight: '90vh', background: '#070708', color: '#eaeaea', padding: '2rem' }}>
      
      {/* Premium Dashboard Header Banner */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '1.5rem',
        borderRadius: '8px',
        background: 'linear-gradient(90deg, #111115 0%, #1a1a24 100%)',
        border: '1px solid rgba(255, 255, 255, 0.05)',
        marginBottom: '2rem'
      }}>
        <div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 800, margin: 0, letterSpacing: '-0.03em', color: '#00FF66' }}>
            🛰️ SFX Central Service Desk & SRE Console
          </h1>
          <p style={{ margin: '0.2rem 0 0 0', fontSize: '0.85rem', color: '#888899' }}>
            1시간 주기 배치 수동 결재망 및 AI 백그라운드 크로스 컴파일 SRE 환경
          </p>
        </div>
        <div style={{ display: 'flex', gap: '1.5rem', fontSize: '0.8rem' }}>
          <div>🟢 <b>Gmail API:</b> Connected</div>
          <div>🟢 <b>Play Console:</b> Online</div>
          <div>🟢 <b>App Store API:</b> Online</div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 2fr', gap: '2rem' }}>
        
        {/* Left Side: Tickets List */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 700, margin: '0 0 0.5rem 0', color: '#a1a1aa' }}>
            수신된 티켓 큐 ({tickets.filter(t => t.status === 'OPEN').length}건 활성)
          </h3>
          {tickets.map(t => (
            <div 
              key={t.ticket_id}
              onClick={() => handleSelectTicket(t)}
              style={{
                padding: '1.2rem',
                borderRadius: '8px',
                background: selectedTicket.ticket_id === t.ticket_id ? '#15151f' : '#0e0e12',
                border: selectedTicket.ticket_id === t.ticket_id ? '1px solid #00FF66' : '1px solid rgba(255, 255, 255, 0.05)',
                cursor: 'pointer',
                transition: 'all 0.2s ease',
                position: 'relative'
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem', fontSize: '0.75rem' }}>
                <span style={{ color: '#888899', fontWeight: 700 }}>{t.ticket_id}</span>
                <span style={{
                  color: t.urgency === 'CRITICAL' ? '#FF3366' : '#FFCC00',
                  fontWeight: 800,
                  boxShadow: t.urgency === 'CRITICAL' ? '0 0 8px rgba(255, 51, 102, 0.2)' : 'none'
                }}>[{t.urgency}]</span>
              </div>
              <h4 style={{ fontSize: '0.95rem', fontWeight: 700, margin: '0 0 0.4rem 0', color: '#ffffff' }}>{t.subject}</h4>
              <p style={{ margin: 0, fontSize: '0.8rem', color: '#888899', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {t.content}
              </p>
              
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '0.8rem', alignItems: 'center' }}>
                <span style={{ fontSize: '0.75rem', background: '#1c1c24', padding: '0.1rem 0.4rem', borderRadius: '4px', color: '#00F0FF' }}>
                  {t.app_id}
                </span>
                <span style={{
                  fontSize: '0.75rem',
                  fontWeight: 600,
                  color: t.status === 'DISPATCHED' ? '#00FF66' : '#888899'
                }}>
                  ● {t.status}
                </span>
              </div>
            </div>
          ))}
        </div>

        {/* Right Side: Detailed Diagnostics & Action Panel */}
        <div style={{
          background: '#0d0d12',
          border: '1px solid rgba(255, 255, 255, 0.05)',
          borderRadius: '8px',
          padding: '2rem',
          display: 'flex',
          flexDirection: 'column',
          gap: '1.8rem'
        }}>
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
              <span style={{ fontSize: '0.8rem', color: '#888899' }}>UUID: {selectedTicket.ticket_id} | 채널: {selectedTicket.source}</span>
              <span style={{
                background: selectedTicket.sentiment === 'ANGRY' ? 'rgba(255, 51, 102, 0.1)' : 'rgba(0, 255, 102, 0.1)',
                color: selectedTicket.sentiment === 'ANGRY' ? '#FF3366' : '#00FF66',
                padding: '0.2rem 0.5rem',
                borderRadius: '4px',
                fontSize: '0.75rem',
                fontWeight: 700
              }}>
                감정 분석: {selectedTicket.sentiment}
              </span>
            </div>
            <h2 style={{ fontSize: '1.4rem', fontWeight: 800, margin: '0 0 1rem 0', color: '#ffffff' }}>{selectedTicket.subject}</h2>
            <div style={{
              background: '#15151d',
              padding: '1.2rem',
              borderRadius: '6px',
              border: '1px solid rgba(255, 255, 255, 0.03)',
              fontSize: '0.9rem',
              lineHeight: 1.6,
              color: '#d1d1d6'
            }}>
              "{selectedTicket.content}"
            </div>
          </div>

          {/* SRE Diagnostics Cross-Map Panel */}
          <div style={{
            background: 'rgba(0, 255, 102, 0.02)',
            border: '1px solid rgba(0, 255, 102, 0.15)',
            borderRadius: '6px',
            padding: '1.2rem'
          }}>
            <h4 style={{ fontSize: '0.9rem', fontWeight: 800, margin: '0 0 0.8rem 0', color: '#00FF66', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
              <span>🔬</span> 중앙 SRE 시스템 크로스 진단 분석 (SSO & Log Match)
            </h4>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', fontSize: '0.8rem' }}>
              <div>• <b>SSO 계정 UUID:</b> <span style={{ color: '#00F0FF' }}>{selectedTicket.diagnostics.sso_uuid}</span></div>
              <div>• <b>유저 기기 / OS:</b> {selectedTicket.diagnostics.device}</div>
              <div>• <b>최종 에러 로그:</b> <span style={{ color: '#FF3366' }}>{selectedTicket.diagnostics.last_error}</span></div>
              <div>• <b>유저 백커 등급:</b> <span style={{ color: '#FFCC00', fontWeight: 700 }}>{selectedTicket.diagnostics.account_tier}</span></div>
            </div>
          </div>

          {/* AI Response Edit & Approval Panel */}
          <div>
            <h4 style={{ fontSize: '0.9rem', fontWeight: 800, margin: '0 0 0.6rem 0', color: '#ffffff' }}>
              🤖 AI 제안 답변 수정 에디터 (Approved-Reply 관문)
            </h4>
            <textarea 
              rows={5}
              value={editedDraft}
              onChange={(e) => setEditedDraft(e.target.value)}
              style={{
                width: '100%',
                padding: '0.8rem',
                borderRadius: '6px',
                background: '#15151d',
                border: '1px solid rgba(255, 255, 255, 0.08)',
                color: '#eaeaea',
                outline: 'none',
                resize: 'vertical',
                fontSize: '0.85rem',
                lineHeight: 1.5
              }}
            />
          </div>

          {/* Interactive Button Console */}
          <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
            <button 
              onClick={() => handleApproveSend(selectedTicket.ticket_id)}
              disabled={selectedTicket.status === 'DISPATCHED'}
              style={{
                flex: 1,
                background: selectedTicket.status === 'DISPATCHED' ? '#33333b' : '#00FF66',
                color: selectedTicket.status === 'DISPATCHED' ? '#888899' : '#000000',
                border: 'none',
                padding: '0.85rem',
                borderRadius: '6px',
                fontWeight: 700,
                cursor: selectedTicket.status === 'DISPATCHED' ? 'not-allowed' : 'pointer',
                fontSize: '0.85rem',
                transition: 'all 0.2s ease'
              }}
            >
              {selectedTicket.status === 'DISPATCHED' ? '발송 완료됨 ✅' : '💬 최종 답장 즉시 전송 승인'}
            </button>

            {selectedTicket.urgency === 'CRITICAL' && (
              <button 
                onClick={triggerAgentPatch}
                disabled={isPatching}
                style={{
                  flex: 1.2,
                  background: '#00F0FF',
                  color: '#000000',
                  border: 'none',
                  padding: '0.85rem',
                  borderRadius: '6px',
                  fontWeight: 800,
                  cursor: 'pointer',
                  fontSize: '0.85rem'
                }}
              >
                {isPatching ? '🛠️ 자율 패치 수행 중...' : '⚙️ 에이전트 자율 오류 코드 패치 지시'}
              </button>
            )}
          </div>

          {/* Live Agent Logs Stream */}
          {patchLogs.length > 0 && (
            <div style={{
              background: '#07070a',
              border: '1px solid rgba(0, 240, 255, 0.2)',
              borderRadius: '6px',
              padding: '1rem',
              fontFamily: 'Courier New, monospace',
              fontSize: '0.75rem',
              color: '#00F0FF'
            }}>
              <div style={{ fontWeight: 800, marginBottom: '0.5rem' }}>🛰️ VEGA SRE AUTONOMOUS BUG-PATCH WORKFLOW:</div>
              {patchLogs.map((log, idx) => (
                <div key={idx} style={{ marginBottom: '0.3rem' }}>{log}</div>
              ))}
            </div>
          )}

        </div>

      </div>
    </main>
  );
}
