"use client";

import { useState, useEffect } from "react";
import styles from "./page.module.css";

// --- Mock Data for Product Modals ---
const productDetails: Record<string, any> = {
  lifelog: {
    title: "Solve-for-X Life-Log",
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
  finance: {
    title: "Solve-for-X Finance",
    icon: "📈",
    features: [
      {
        title: "무한매수 알고리즘",
        description: "개인의 뇌동매매를 100% 차단하며, 리스크를 완전히 분산하는 수학적 알고리즘(Infinite Buy Method)을 구동합니다."
      },
      {
        title: "헤드리스 백엔드 연동",
        description: "거래소 API와 직접 연결된 Core Engine이 사람의 수면 시간에도 끊임없이 로직을 점검하고 주문을 체결합니다."
      },
      {
        title: "시각화 대시보드",
        description: "현재 자산 배분 비중, 핑퐁 거래 수익률 등을 오해의 여지 없이 직관적인 웹 대시보드로 브리핑합니다."
      }
    ]
  },
  core: {
    title: "Solve-for-X Core Engine",
    icon: "⚡️",
    features: [
      {
        title: "Java / Spring Boot 코어",
        description: "가장 견고한 엔터프라이즈급 생태계를 보장하기 위해, 모든 데이터 정합성은 강력한 타입스크립팅과 마이크로서비스로 검증됩니다."
      },
      {
        title: "AI 추론 엔진 통합",
        description: "Qwen3-Coder 30B 로컬 모델과 직접 연결되어, 고객의 프라이버시 데이터를 외부 오픈AI 등에 절대 전송하지 않습니다."
      },
      {
        title: "Zero-Downtime 통제",
        description: "모든 시스템은 컨테이너화되어 있으며, 어떠한 상황에서도 99.9%의 서비스 무결성을 유지하는 심장과도 같은 인프라입니다."
      }
    ]
  }
};

export default function Home() {
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [activeModal, setActiveModal] = useState<string | null>(null);

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
            {/* Life-Log App */}
            <div className={styles.appCard} onClick={() => setActiveModal('lifelog')}>
              <div className={styles.appHeader}>
                <div className={styles.appName}>SFX Life-Log</div>
                <div className={styles.appStatus}>
                  <span className={`${styles.statusDot} ${styles.statusWait}`}></span>
                  Coming 2026 Q3
                </div>
              </div>
              <p className={styles.appDesc}>
                나의 흩어진 감정과 서사를 온전히 기록하고 보존하는 멀티모달 AI 아이덴티티 프로덕트. 잃어버리는 기억 없이 영원한 레거시를 완성합니다.
              </p>
              <div className={styles.cardAction}>자세히 보기 <span>→</span></div>
            </div>

            {/* Finance Dashboard */}
            <div className={styles.appCard} onClick={() => setActiveModal('finance')}>
              <div className={styles.appHeader}>
                <div className={styles.appName}>SFX Finance</div>
                <div className={styles.appStatus}>
                  <span className={`${styles.statusDot} ${styles.statusWait}`}></span>
                  Planning Phase
                </div>
              </div>
              <p className={styles.appDesc}>
                수면 시간을 방해받지 않도록 모든 감정과 뇌동매매를 배제한, 자산 관리 지수 추종형 자동화 파이프라인. 알고리즘 기반으로 당신의 자본을 지킵니다.
              </p>
              <div className={styles.cardAction}>자세히 보기 <span>→</span></div>
            </div>

            {/* Core Engine */}
            <div className={styles.appCard} style={{ gridColumn: '1 / -1' }} onClick={() => setActiveModal('core')}>
              <div className={styles.appHeader}>
                <div className={styles.appName}>SFX Core Engine</div>
                <div className={styles.appStatus}>
                  <span className={`${styles.statusDot} ${styles.statusLive}`}></span>
                  System Live
                </div>
              </div>
              <p className={styles.appDesc}>
                안정성 99.9%를 타겟으로 구축된 백엔드 인프라. 모든 앱의 데이터 무결성을 실시간으로 보장하며, 로컬 AI 추론 엔진과 결속된 철벽의 시스템 심장입니다.
              </p>
              <div className={styles.cardAction}>아키텍처 스펙 보기 <span>→</span></div>
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
