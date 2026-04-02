package com.soluni.legacycore.domain.lifelog;

import com.soluni.legacycore.domain.base.BaseTimeEntity;
import com.soluni.legacycore.domain.member.Member;
import jakarta.persistence.*;

@Entity
@Table(name = "life_log")
public class LifeLog extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Column(name = "emotion_score")
    private Integer emotionScore; // e.g., 0 to 100

    @Column(name = "media_url")
    private String mediaUrl;

    protected LifeLog() {}

    public LifeLog(Member member, String content, Integer emotionScore, String mediaUrl) {
        this.member = member;
        this.content = content;
        this.emotionScore = emotionScore;
        this.mediaUrl = mediaUrl;
    }

    public Long getId() { return id; }
    public Member getMember() { return member; }
    public String getContent() { return content; }
    public Integer getEmotionScore() { return emotionScore; }
    public String getMediaUrl() { return mediaUrl; }
}
