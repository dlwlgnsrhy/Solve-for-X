package com.soluni.legacycore.domain.member;

import com.soluni.legacycore.domain.base.BaseTimeEntity;
import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "member")
public class Member extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String role; // e.g. "ROLE_ARCHITECT", "ROLE_USER"

    @Column(unique = true, updatable = false)
    private String uuid;

    protected Member() {
        // JPA standard
    }

    public Member(String email, String password, String role) {
        this.email = email;
        this.password = password;
        this.role = role;
        this.uuid = UUID.randomUUID().toString();
    }

    public Long getId() { return id; }
    public String getEmail() { return email; }
    
    @com.fasterxml.jackson.annotation.JsonIgnore
    public String getPassword() { return password; }
    
    public String getRole() { return role; }
    public String getUuid() { return uuid; }
}
