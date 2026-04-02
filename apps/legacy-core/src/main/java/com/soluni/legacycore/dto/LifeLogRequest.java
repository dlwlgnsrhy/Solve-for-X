package com.soluni.legacycore.dto;

public class LifeLogRequest {
    private String content;
    private Integer emotionScore;
    private String mediaUrl;

    public LifeLogRequest() {}

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Integer getEmotionScore() { return emotionScore; }
    public void setEmotionScore(Integer emotionScore) { this.emotionScore = emotionScore; }

    public String getMediaUrl() { return mediaUrl; }
    public void setMediaUrl(String mediaUrl) { this.mediaUrl = mediaUrl; }
}
