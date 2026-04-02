package com.soluni.legacycore.controller;

import com.soluni.legacycore.domain.lifelog.LifeLog;
import com.soluni.legacycore.dto.CommonResponse;
import com.soluni.legacycore.dto.LifeLogRequest;
import com.soluni.legacycore.service.LifeLogService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/lifelogs")
public class LifeLogController {

    private final LifeLogService lifeLogService;

    public LifeLogController(LifeLogService lifeLogService) {
        this.lifeLogService = lifeLogService;
    }

    @PostMapping
    public ResponseEntity<CommonResponse<LifeLog>> createLog(@RequestBody LifeLogRequest request, Authentication authentication) {
        String email = authentication.getName();
        LifeLog log = lifeLogService.createLog(email, request);
        return ResponseEntity.ok(CommonResponse.success(log));
    }

    @GetMapping
    public ResponseEntity<CommonResponse<List<LifeLog>>> getMyLogs(Authentication authentication) {
        String email = authentication.getName();
        List<LifeLog> logs = lifeLogService.getMyLogs(email);
        return ResponseEntity.ok(CommonResponse.success(logs));
    }
}
