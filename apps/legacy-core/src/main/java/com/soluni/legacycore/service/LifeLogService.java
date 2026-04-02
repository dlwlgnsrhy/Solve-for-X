package com.soluni.legacycore.service;

import com.soluni.legacycore.domain.lifelog.LifeLog;
import com.soluni.legacycore.domain.lifelog.LifeLogRepository;
import com.soluni.legacycore.domain.member.Member;
import com.soluni.legacycore.domain.member.MemberRepository;
import com.soluni.legacycore.dto.LifeLogRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class LifeLogService {

    private final LifeLogRepository lifeLogRepository;
    private final MemberRepository memberRepository;

    public LifeLogService(LifeLogRepository lifeLogRepository, MemberRepository memberRepository) {
        this.lifeLogRepository = lifeLogRepository;
        this.memberRepository = memberRepository;
    }

    @Transactional
    public LifeLog createLog(String email, LifeLogRequest request) {
        Member member = memberRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        LifeLog log = new LifeLog(member, request.getContent(), request.getEmotionScore(), request.getMediaUrl());
        return lifeLogRepository.save(log);
    }

    public List<LifeLog> getMyLogs(String email) {
        Member member = memberRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Member not found"));

        return lifeLogRepository.findByMemberIdOrderByCreatedAtDesc(member.getId());
    }
}
