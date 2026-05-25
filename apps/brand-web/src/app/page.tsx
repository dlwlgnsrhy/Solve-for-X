"use client";

import { useState, useEffect } from "react";
import styles from "./page.module.css";

// --- Mock Data for Product Modals ---
const productDetails: Record<string, any> = {
  lifelog: {
    title: "Solve-for-X Life-Log (Moon Whisper)",
    icon: "📖",
    features: [
      {
        title: "멀티모달 감정 인식",
        description: "단순한 텍스트를 넘어 당신의 음성과 사진을 AI가 분석하여 당일의 입체적인 서사를 저장합니다."
      },
      {
        title: "영구적 데이터 주권",
        description: "모든 일기는 플러터(Flutter) 기반 네이티브 앱을 통해 수집되며, 해시 암호화되어 분산 저장됩니다."
      },
      {
        title: "자동 회고 생성 (Qwen3)",
        description: "주말마다 로컬 AI 머신이 당신의 한 주를 회고하고, 올바른 삶의 방향성을 위한 통찰을 브리핑합니다."
      }
    ]
  },
  imjong: {
    title: "SFX Imjong Care (임종케어)",
    icon: "🌸",
    features: [
      {
        title: "암호화된 디지털 유언장",
        description: "로컬에서 강력한 AES-256 알고리즘으로 유언장을 암호화하여 DB 보안 유출 시에도 안전합니다."
      },
      {
        title: "감성적 네온 카드 비주얼",
        description: "Orbitron/Inter 폰트와 핫핑크 글로우 네온 액센트를 매핑하여 지극히 아름답고 엄숙한 성찰 경험을 빚어냅니다."
      },
      {
        title: "100% 무인 로컬 아키텍처",
        description: "Zero-Server 원칙을 적용하여 유저의 민감한 성찰 및 프라이버시가 클라우드에 노출되는 것을 완전 차단합니다."
      }
    ]
  },
  mementomori: {
    title: "SFX Memento Mori (메멘토 모리)",
    icon: "⌛",
    features: [
      {
        title: "4,160주 생애 그리드 시각화",
        description: "GridView 최적화 렌더러를 탑재하여 메모리 부하 없이 80년 수명의 흘러간 시간과 다가올 주차를 선명하게 체감합니다."
      },
      {
        title: "네온 그린 시그니처 테마",
        description: "Neon Green 라이트 글로우 테마의 시각적 디자인으로 어둠 속에서 빛나는 삶의 원초적 에너지를 시각화합니다."
      },
      {
        title: "로컬 자가 완결형 상태",
        description: "SharedPreferences 기반 무인 데이터 오프라인 자급형으로 기기 분실 전까지 데이터를 완벽 보존합니다."
      }
    ]
  },
  factory: {
    title: "Sisyphus Factory (자율 에이전트 공장)",
    icon: "⚙️",
    features: [
      {
        title: "Telegram Commander 연동",
        description: "1-Click 인라인 승인 보드와 실시간 SRE 모니터링 데몬이 결합된 완벽 무인 자율 오케스트레이터."
      },
      {
        title: "3-Cycle 자율 검증 QA",
        description: "개발 완료 시 AI 에이전트가 `analyze` 및 전체 테스트 스위트를 구동하여 무결성을 입증하기 전까지 릴리즈하지 않습니다."
      },
      {
        title: "Fastlane Zero-Intervention 배포",
        description: "인증서 동기화(Match) 및 ASC API key 연동을 통해 빌드부터 심사 제출까지 터치 없이 자율 질주합니다."
      }
    ]
  },
  core: {
    title: "SFX Core Basecamp (통합 백엔드)",
    icon: "⚡️",
    features: [
      {
        title: "단일 Flat-rate 가상화 인프라",
        description: "BaaS의 무제한 추가 과금을 배제하고 월 $5 플랫 레이트 VPS 위에 Docker-compose로 자가 호스팅되는 PostgreSQL 통합망."
      },
      {
        title: "멀티테넌트 스키마 격리",
        description: "하나의 DB 인스턴스 안에서 격리된 독자 스키마를 가동하되, 통합 SSO 유저 매핑 테이블을 공유하여 크로스폴리네이션을 활성화합니다."
      },
      {
        title: "Zero-Downtime 통제",
        description: "모든 서비스는 컨테이너화되어 있으며, 어떠한 상황에서도 99.9%의 서비스 무결성을 유지하는 심장과도 같은 인프라입니다."
      }
    ]
  }
};

export default function Home() {
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [activeModal, setActiveModal] = useState<string | null>(null);
  const [sreStatus, setSreStatus] = useState<"LIVE" | "OFFLINE" | "CHECKING">("CHECKING");
  const [sreLatency, setSreLatency] = useState<number | null>(null);

  // SRE Health Check Polling
  useEffect(() => {
    const checkHealth = async () => {
      try {
        const basePath = process.env.NEXT_PUBLIC_BASE_PATH || '';
        const res = await fetch(`${basePath}/api/sre/health`);
        if (res.ok) {
          const data = await res.json();
          setSreStatus("LIVE");
          setSreLatency(data.latency);
        } else {
          setSreStatus("OFFLINE");
          setSreLatency(null);
        }
      } catch (e) {
        setSreStatus("OFFLINE");
        setSreLatency(null);
      }
    };
    
    checkHealth();
    const interval = setInterval(checkHealth, 10000);
    return () => clearInterval(interval);
  }, []);

  // 대화형 배경 (Spotlight) 마우스 트래킹
  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setMousePos({ x: e.clientX, y: e.clientY });
    };
    window.addEventListener("mousemove", handleMouseMove);
    return () => window.removeEventListener("mousemove", handleMouseMove);
  }, []);

  // 모달 스크롤 방지
  useEffect(() => {
    if (activeModal) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "auto";
    }
  }, [activeModal]);

  return (
    <main className={styles.container}>
      {/* Interactive Background */}
      <div 
        className={styles.spotlight} 
        style={{ 
          "--mouse-x": `${mousePos.x}px`, 
          "--mouse-y": `${mousePos.y}px` 
        } as React.CSSProperties} 
      />

      <div className={styles.contentWrapper}>
        {/* 1. Brand Vision & Hero */}
        <section id="vision" className={styles.hero}>
          <h1 className={styles.title}>The Tech of Human Dignity</h1>
          <p className={styles.subtitle}>
            Solve-for-X는 기술과 시스템 자동화를 통해 인간의 삶에서 반복되는 낭비를 제거하고,
            유한한 시간과 디지털 존엄성을 인류에게 돌려주는 거대한 생태계를 짓습니다.
          </p>
        </section>

        {/* 2. Founder's Letter (창업자의 편지) */}
        <section id="founder" className={styles.founder}>
          <div className={styles.founderContent}>
            <div className={styles.founderTitle}>"시간은 유일하게 돈으로 매수할 수 없는 가장 비싼 자산입니다."</div>
            <div className={styles.founderText}>
              <p>
                우리는 매일 반복되는 잡무와 피로, 그리고 사라져버리는 감정들 속에서 
                인생의 가장 귀중한 '존엄성'을 잃어갑니다. 
                Solve-for-X는 이 거대한 낭비의 고리를 끊어내기 위해 설계된 <strong>개인용 엔터프라이즈 아키텍처</strong>입니다.
              </p>
              <p>
                이곳은 단순한 앱 홈페이지가 아닙니다. 재무(Finance)부터 생애 기록(Life-Log)까지, 당신의 삶 전체를 백업하고 보호하는, 절대 멈추지 않는 글로벌 로컬 시스템의 코어를 짓고 있습니다.
              </p>
              <p>
                고객은 당신의 고귀한 삶에만 집중하십시오. 나머지 모든 통제와 기록의 연산은 저희 시스템이 증명해 내겠습니다.
              </p>
              <div className={styles.founderSign}>
                <strong>Jihoon Lee</strong>
                <span>Founder & Chief Architect, soluni</span>
              </div>
            </div>
          </div>
        </section>

        {/* 3. App Ecosystem */}
        <section id="ecosystem" className={styles.ecosystem}>
          <div className={styles.sectionHeader}>
            <h2 className={styles.sectionTitle}>Product Ecosystem</h2>
            <p className={styles.sectionSubtitle}>상호 연결되어 완벽한 자동화를 이루어내는 모듈들</p>
          </div>
          
          <div className={styles.appGrid}>
            {/* 1. Life-Log App */}
            <div className={styles.appCard} onClick={() => window.open('https://play.google.com/store/apps/details?id=com.moon_whisper.mw', '_blank')}>
              <div className={styles.appHeader}>
                <div className={styles.appName}>SFX Life-Log</div>
                <div className={styles.appStatus}>
                  <span className={`${styles.statusDot} ${styles.statusLive}`}></span>
                  Available on Play Store
                </div>
              </div>
              <p className={styles.appDesc}>
                나의 흩어진 감정과 서사를 온전히 기록하고 보존하는 멀티모달 AI 아이덴티티 프로덕트. 잃어버리는 기억 없이 영원한 레거시를 완성합니다.
              </p>
              <div className={styles.cardAction}>Google Play 설치 <span>↗</span></div>
            </div>

            {/* 2. SFX Imjong Care */}
            <div className={styles.appCard} onClick={() => setActiveModal('imjong')}>
              <div className={styles.appHeader}>
                <div className={styles.appName}>SFX Imjong Care</div>
                <div className={styles.appStatus}>
                  <span className={`${styles.statusDot} ${styles.statusLive}`}></span>
                  TestFlight Build Ready
                </div>
              </div>
              <p className={styles.appDesc}>
                핫핑크 글로우 네온 비주얼로 탄생한 디지털 유언장 성찰 플랫폼. AES-256 로컬 암호화 장벽으로 완벽한 프라이버시 존엄성을 사수합니다.
              </p>
              <div className={styles.cardAction}>자세히 보기 / 정책 확인 <span>→</span></div>
            </div>

            {/* 3. SFX Memento Mori */}
            <div className={styles.appCard} onClick={() => setActiveModal('mementomori')}>
              <div className={styles.appHeader}>
                <div className={styles.appName}>SFX Memento Mori</div>
                <div className={styles.appStatus}>
                  <span className={`${styles.statusDot} ${styles.statusLive}`}></span>
                  100% Green Tested
                </div>
              </div>
              <p className={styles.appDesc}>
                생애 4,160주의 격자를 최적화된 GridView로 직관 시각화하는 생의 자각 플랫폼. 네온 그린 컬러의 시각적 에너지로 죽음을 인지하여 삶을 채웁니다.
              </p>
              <div className={styles.cardAction}>자세히 보기 / 정책 확인 <span>→</span></div>
            </div>

            {/* 4. Sisyphus Factory */}
            <div className={styles.appCard} onClick={() => window.location.href = '/factory'}>
              <div className={styles.appHeader}>
                <div className={styles.appName}>Sisyphus Factory</div>
                <div className={styles.appStatus}>
                  <span className={`${styles.statusDot} ${styles.statusLive}`}></span>
                  Commander Online
                </div>
              </div>
              <p className={styles.appDesc}>
                설계도 하나만 전달하면 코딩, QA 검증, Fastlane 앱스토어 제출 및 Vercel 웹 릴리즈까지 완전 무인 처리하는 자율형 소프트웨어 공장.
              </p>
              <div className={styles.cardAction}>실시간 공장 모니터링 기동 <span>→</span></div>
            </div>

            {/* 5. SFX Core Basecamp */}
            <div className={styles.appCard} onClick={() => setActiveModal('core')}>
              <div className={styles.appHeader}>
                <div className={styles.appName}>SFX Basecamp</div>
                <div className={styles.appStatus}>
                  <span className={`${styles.statusDot} ${sreStatus === 'LIVE' ? styles.statusLive : sreStatus === 'OFFLINE' ? styles.statusOffline : styles.statusWait}`}></span>
                  {sreStatus === 'LIVE' ? 'System Live' : sreStatus === 'OFFLINE' ? 'System Offline' : 'Checking Status...'}
                  {sreStatus === 'LIVE' && sreLatency && ` (${sreLatency}ms)`}
                </div>
              </div>
              <p className={styles.appDesc}>
                단일 플랫 레이트 VPS 위에 Docker-compose PostgreSQL 멀티 스키마로 자가 호스팅되는 플랫폼 통합 DB 심장부.
              </p>
              <div className={styles.cardAction}>통합 DB 스펙 보기 <span>→</span></div>
            </div>

            {/* 6. SRE Blog */}
            <div className={styles.appCard} onClick={() => window.open('https://medium.com/@dlwlgnsrhy/ai-transformation-chapter1-3a4b88302aef', '_blank')}>
              <div className={styles.appHeader}>
                <div className={styles.appName}>SRE Blog</div>
                <div className={styles.appStatus}>
                  <span className={`${styles.statusDot} ${styles.statusLive}`}></span>
                  Latest Chapter
                </div>
              </div>
              <p className={styles.appDesc}>
                기술과 철학의 융합. AI 자동화 시스템을 구축하며 얻은 아키텍처적 통찰과 SRE 여정을 기록합니다.
              </p>
              <div className={styles.cardAction}>Medium 읽기 <span>↗</span></div>
            </div>
          </div>
        </section>

        {/* 4. Core Principles */}
        <section id="principles" className={styles.principles}>
          <div className={styles.sectionHeader}>
            <h2 className={styles.sectionTitle}>Core Principles</h2>
            <p className={styles.sectionSubtitle}>우리가 타협하지 않는 세 가지 신뢰의 원칙</p>
          </div>

          <div className={styles.principleGrid}>
            <div className={styles.principleItem}>
              <div className={styles.principleIcon}>⚡️</div>
              <h3 className={styles.principleTitle}>Absolute Automation</h3>
              <p className={styles.principleDesc}>
                불편한 수작업에 시간을 빼앗기지 않도록 모든 결정과 절차를 시스템 위에서 완벽히 연동시킵니다.
              </p>
            </div>
            
            <div className={styles.principleItem}>
              <div className={styles.principleIcon}>🛡️</div>
              <h3 className={styles.principleTitle}>Data Sovereignty</h3>
              <p className={styles.principleDesc}>
                사용자 데이터를 외부 빅테크에 무분별하게 종속시키지 않고 개인의 소유로 보존하는 로컬 중심 기반 보안을 추구합니다.
              </p>
            </div>

            <div className={styles.principleItem}>
              <div className={styles.principleIcon}>♾️</div>
              <h3 className={styles.principleTitle}>Uncompromising Stability</h3>
              <p className={styles.principleDesc}>
                엔터프라이즈 SRE 아키텍처. 절대 멈추거나 휘발되지 않는 영구적인 디지털 유산 보존을 약속합니다.
              </p>
            </div>
          </div>
        </section>
      </div>

      {/* Product Deep-Dive Modal Overlay */}
      {activeModal && productDetails[activeModal] && (
        <div className={styles.modalOverlay} onClick={() => setActiveModal(null)}>
          <div className={styles.modalWindow} onClick={e => e.stopPropagation()}>
            <div className={styles.modalHeader}>
              <h3 className={styles.modalTitle}>{productDetails[activeModal].title}</h3>
              <button className={styles.closeButton} onClick={() => setActiveModal(null)}>×</button>
            </div>
            <div className={styles.modalBody}>
              <div className={styles.modalImageSkeleton}>
                {productDetails[activeModal].icon}
                <span className={styles.skeletonText}>Interactive Architecture View Placeholder</span>
              </div>
              <div className={styles.modalFeatures}>
                {productDetails[activeModal].features.map((feature: any, idx: number) => (
                  <div key={idx} className={styles.featureItem}>
                    <h4>{feature.title}</h4>
                    <p>{feature.description}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
