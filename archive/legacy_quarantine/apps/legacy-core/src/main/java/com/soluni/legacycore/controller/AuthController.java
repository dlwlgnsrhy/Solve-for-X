package com.soluni.legacycore.controller;

import com.soluni.legacycore.dto.CommonResponse;
import com.soluni.legacycore.dto.LoginRequest;
import com.soluni.legacycore.service.AuthService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<CommonResponse<Map<String, String>>> login(@RequestBody LoginRequest request) {
        try {
            Map<String, String> token = authService.login(request.getEmail(), request.getPassword());
            return ResponseEntity.ok(CommonResponse.success(token));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(401).body(CommonResponse.error(e.getMessage()));
        }
    }
}
