package com.soluni.legacycore.domain.lifelog;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface LifeLogRepository extends JpaRepository<LifeLog, Long> {
    List<LifeLog> findByMemberIdOrderByCreatedAtDesc(Long memberId);
}
