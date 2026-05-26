package com.soluni.legacycore.domain.finance;

import com.soluni.legacycore.domain.base.BaseTimeEntity;
import com.soluni.legacycore.domain.member.Member;
import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "asset")
public class Asset extends BaseTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    @Column(nullable = false)
    private String ticker;

    @Column(name = "average_price", precision = 19, scale = 4)
    private BigDecimal averagePrice;

    @Column(name = "quantity", precision = 19, scale = 4)
    private BigDecimal quantity;

    @Column(name = "target_weight")
    private Integer targetWeight; // 0 to 100 percentage

    protected Asset() {}

    public Asset(Member member, String ticker, BigDecimal averagePrice, BigDecimal quantity, Integer targetWeight) {
        this.member = member;
        this.ticker = ticker;
        this.averagePrice = averagePrice;
        this.quantity = quantity;
        this.targetWeight = targetWeight;
    }

    public Long getId() { return id; }
    public Member getMember() { return member; }
    public String getTicker() { return ticker; }
    public BigDecimal getAveragePrice() { return averagePrice; }
    public BigDecimal getQuantity() { return quantity; }
    public Integer getTargetWeight() { return targetWeight; }
}
