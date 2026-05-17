import React from 'react';
import Link from 'next/link';
import { notFound } from 'next/navigation';

// Type definitions
interface PolicyContent {
  title: string;
  lastUpdated: string;
  sections: {
    heading: string;
    paragraphs: string[];
  }[];
}

interface AppPolicies {
  name: string;
  neonColor: string;
  glowColor: string;
  privacy: PolicyContent;
  eula: PolicyContent;
}

// Policies mapping database
const policiesDB: Record<string, AppPolicies> = {
  'imjong-care': {
    name: 'SFX Imjong Care (임종케어)',
    neonColor: '#FF0055', // Hot Pink
    glowColor: 'rgba(255, 0, 85, 0.4)',
    privacy: {
      title: '개인정보 처리방침 (Privacy Policy)',
      lastUpdated: '2026년 5월 17일',
      sections: [
        {
          heading: '1. 수집하는 개인정보 항목',
          paragraphs: [
            'SFX Imjong Care(이하 "서비스")는 전적으로 사용자의 모바일 기기 내부 저장소(SharedPreferences, SecureStorage)에 데이터를 저장하며, 외부 서버로 유저의 개인 식별 정보를 전송하거나 수집하지 않는 "Zero-Server" 아키텍처를 원칙으로 합니다.',
            '다만, 사용자가 작성하는 유언장(Wills) 등 민감한 텍스트 데이터는 기기 로컬 내에서 암호화되어 저장됩니다.'
          ]
        },
        {
          heading: '2. 개인정보의 이용 목적',
          paragraphs: [
            '서비스는 오직 유언장의 생성, 네온 테마 카드 시각화 및 로컬 백업 등의 기능을 정상 제공하기 위한 목적으로만 기기 내 자원을 활용합니다.'
          ]
        },
        {
          heading: '3. 제3자 제공 및 위탁',
          paragraphs: [
            '서비스는 어떠한 경우에도 사용자의 명시적 동의 없이 개인정보를 제3자에게 제공하거나 외부 기관에 위탁하지 않습니다.'
          ]
        }
      ]
    },
    eula: {
      title: '최종 사용자 라이선스 계약 (EULA)',
      lastUpdated: '2026년 5월 17일',
      sections: [
        {
          heading: '1. 서비스 이용 제한',
          paragraphs: [
            '사용자는 본 서비스를 타인의 권리를 침해하거나 불법적인 유언 및 명예훼손 콘텐츠를 조작하는 행위에 사용할 수 없습니다.'
          ]
        },
        {
          heading: '2. 지적 재산권',
          paragraphs: [
            '서비스 내에서 제공되는 모든 네온 비주얼 셰이더, 테마 디자인, 카드 프레임 및 Orbitron/Inter 폰트 바인딩 등의 독창적인 자산은 Solve-for-X 브랜드의 지적재산입니다.'
          ]
        },
        {
          heading: '3. 면책 조항',
          paragraphs: [
            '본 서비스는 로컬 기기 보존형 유언 작성을 지원하는 성찰 앱으로, 법적 공증이나 유산 상속 분쟁 조정을 보장하는 사법적 문서의 효력을 갖지 않습니다. 법률적 공증이 필요한 경우 별도의 전문 법률 조력을 받아야 합니다.'
          ]
        }
      ]
    }
  },
  'memento-mori': {
    name: 'SFX Memento Mori (메멘토 모리)',
    neonColor: '#00FF66', // Neon Green
    glowColor: 'rgba(0, 255, 102, 0.4)',
    privacy: {
      title: '개인정보 처리방침 (Privacy Policy)',
      lastUpdated: '2026년 5월 17일',
      sections: [
        {
          heading: '1. 개인정보 수집 및 저장',
          paragraphs: [
            'SFX Memento Mori는 생년월일 및 목표 수명 데이터를 바탕으로 4,160주의 생애 그리드를 렌더링하는 앱입니다.',
            '입력하신 생년월일 정보는 전적으로 모바일 기기 내 Local SharedPreferences에만 저장되며, 어떠한 마케팅 추적 도구나 외부 서버로 송신되지 않습니다.'
          ]
        },
        {
          heading: '2. 브라우저 및 앱 분석 도구',
          paragraphs: [
            '앱 스토어 출시를 위한 기본 플랫폼 통계(크래시 보고서) 외에, 유저의 일상적 동선이나 인생 데이터를 트래킹하는 서드파티 광고 라이브러리는 일절 포함하고 있지 않습니다.'
          ]
        }
      ]
    },
    eula: {
      title: '최종 사용자 라이선스 계약 (EULA)',
      lastUpdated: '2026년 5월 17일',
      sections: [
        {
          heading: '1. 라이선스 허가',
          paragraphs: [
            '본 서비스는 개인적 용도의 비상업적 목적에 한해 무료로 라이선스가 허가됩니다.'
          ]
        },
        {
          heading: '2. 서비스 품질 약관',
          paragraphs: [
            '인생 그리드 시각화는 80년 기준 평균적 4,160주의 흐름을 인지시켜 삶의 소중함을 자각하도록 하는 철학적 콘텐츠입니다. 본 정보가 미래 수명의 물리적 확정을 의미하거나 보장하지 않습니다.'
          ]
        }
      ]
    }
  },
  'moon-whisper': {
    name: 'Moon Whisper (문위스퍼)',
    neonColor: '#00FFFF', // Neon Cyan
    glowColor: 'rgba(0, 255, 255, 0.4)',
    privacy: {
      title: '개인정보 처리방침 (Privacy Policy)',
      lastUpdated: '2026년 5월 17일',
      sections: [
        {
          heading: '1. 음성 녹음 데이터 수집 및 관리',
          paragraphs: [
            '사용자가 녹음하는 감정 목소리 파일은 감정 마인드맵 분석 및 파싱 목적에 한해 기기 로컬 AI 모델(LM Studio) 혹은 보안 인가된 VPS 단일 통합 서버(Basecamp)에 전송될 수 있습니다.',
            '전송되는 모든 음성 정보는 전송 구간 내 SSL/TLS로 강력히 보호되며, 복호화 키는 유저 기기에 격리되어 안전하게 보관됩니다.'
          ]
        },
        {
          heading: '2. 위치 정보 및 백그라운드 데이터 수집 차단',
          paragraphs: [
            '사용자가 허용한 마이크 권한 외에 불필요한 위치 추적이나 타 사이트 활동 정보 등의 마케팅성 데이터는 절대 요구하거나 동의 없이 가공하지 않습니다.'
          ]
        }
      ]
    },
    eula: {
      title: '최종 사용자 라이선스 계약 (EULA)',
      lastUpdated: '2026년 5월 17일',
      sections: [
        {
          heading: '1. 마이크로폰 및 음성 데이터 이용 합의',
          paragraphs: [
            '사용자는 음성 분석 기능을 사용하기 위해 기기의 마이크 접근 권한 승인에 동의합니다.',
            '음성 비주얼 분석과 홀로그램 싱크 데이터는 개인의 성찰 연구 보존용으로만 사용되어야 하며, 불법 감청이나 해킹 시도 등 공격 목적으로 사용할 수 없습니다.'
          ]
        }
      ]
    }
  }
};

interface PageProps {
  params: Promise<{
    appId: string;
    type: string;
  }>;
}

export default async function PolicyPage({ params }: PageProps) {
  const { appId, type } = await params;
  const appData = policiesDB[appId];

  // Validate appId and type
  if (!appData || (type !== 'privacy' && type !== 'eula')) {
    notFound();
  }

  const policy = type === 'privacy' ? appData.privacy : appData.eula;

  return (
    <div style={styles.container}>
      {/* Background Neon Glows */}
      <div style={{ ...styles.glowTop, background: `radial-gradient(circle, ${appData.neonColor} 0%, transparent 70%)` }} />
      <div style={styles.glowBottom} />

      <main style={styles.card}>
        {/* Neon Border Highlight */}
        <div style={{ ...styles.neonBorder, borderColor: appData.neonColor, boxShadow: `0 0 20px ${appData.glowColor}` }} />

        {/* Back Link */}
        <div style={styles.headerRow}>
          <span style={{ ...styles.appName, color: appData.neonColor }}>{appData.name}</span>
          <span style={styles.lastUpdated}>최종 갱신일: {policy.lastUpdated}</span>
        </div>

        <h1 style={styles.title}>{policy.title}</h1>
        <div style={styles.divider} />

        <div style={styles.contentArea}>
          {policy.sections.map((section, idx) => (
            <section key={idx} style={styles.section}>
              <h2 style={{ ...styles.sectionHeading, color: appData.neonColor }}>{section.heading}</h2>
              {section.paragraphs.map((p, pIdx) => (
                <p key={pIdx} style={styles.paragraph}>
                  {p}
                </p>
              ))}
            </section>
          ))}
        </div>

        {/* Footer Accent */}
        <div style={styles.footer}>
          <Link href="/" style={styles.backButton}>
            Solve-for-X 브랜드 포탈로 가기
          </Link>
          <span style={styles.copyright}>© 2026 Solve-for-X (SFX). All Rights Reserved.</span>
        </div>
      </main>
    </div>
  );
}

// Inline responsive CSS styles for modern Glassmorphism theme
const styles: Record<string, React.CSSProperties> = {
  container: {
    backgroundColor: '#0A0A0E',
    color: '#E2E8F0',
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '40px 20px',
    fontFamily: '"Inter", "Outfit", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    position: 'relative',
    overflow: 'hidden',
  },
  glowTop: {
    position: 'absolute',
    top: '-200px',
    left: 'calc(50% - 250px)',
    width: '500px',
    height: '500px',
    opacity: 0.25,
    filter: 'blur(80px)',
    pointerEvents: 'none',
  },
  glowBottom: {
    position: 'absolute',
    bottom: '-200px',
    right: '10%',
    width: '400px',
    height: '400px',
    background: 'radial-gradient(circle, #00FFFF 0%, transparent 70%)',
    opacity: 0.15,
    filter: 'blur(80px)',
    pointerEvents: 'none',
  },
  card: {
    position: 'relative',
    backgroundColor: 'rgba(17, 17, 24, 0.75)',
    backdropFilter: 'blur(20px)',
    borderRadius: '24px',
    padding: '48px',
    maxWidth: '800px',
    width: '100%',
    boxSizing: 'border-box',
    border: '1px solid rgba(255, 255, 255, 0.05)',
    display: 'flex',
    flexDirection: 'column',
    zIndex: 10,
  },
  neonBorder: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    borderRadius: '24px',
    borderWidth: '1.5px',
    borderStyle: 'solid',
    pointerEvents: 'none',
    opacity: 0.7,
  },
  headerRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '16px',
    flexWrap: 'wrap',
    gap: '8px',
  },
  appName: {
    fontSize: '14px',
    fontWeight: 'bold',
    letterSpacing: '2px',
  },
  lastUpdated: {
    fontSize: '12px',
    color: '#64748B',
  },
  title: {
    fontSize: '28px',
    fontWeight: 800,
    color: '#FFFFFF',
    margin: '0 0 20px 0',
    letterSpacing: '-0.5px',
  },
  divider: {
    height: '1px',
    background: 'linear-gradient(to right, rgba(255, 255, 255, 0.15), rgba(255, 255, 255, 0))',
    marginBottom: '32px',
  },
  contentArea: {
    display: 'flex',
    flexDirection: 'column',
    gap: '28px',
  },
  section: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
  },
  sectionHeading: {
    fontSize: '18px',
    fontWeight: 700,
    margin: 0,
    letterSpacing: '-0.2px',
  },
  paragraph: {
    fontSize: '15px',
    lineHeight: '1.7',
    color: '#CBD5E1',
    margin: 0,
  },
  footer: {
    marginTop: '48px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: '16px',
    paddingTop: '24px',
    borderTop: '1px solid rgba(255, 255, 255, 0.05)',
  },
  backButton: {
    fontSize: '13px',
    color: '#00FFFF',
    textDecoration: 'none',
    fontWeight: 600,
    transition: 'color 0.2s',
  },
  copyright: {
    fontSize: '11px',
    color: '#475569',
  },
};
