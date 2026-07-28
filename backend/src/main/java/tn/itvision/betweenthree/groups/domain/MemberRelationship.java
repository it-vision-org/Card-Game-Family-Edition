package tn.itvision.betweenthree.groups.domain;

import java.time.Instant;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import tn.itvision.betweenthree.identity.domain.AppUser;

@Entity
@Table(name = "member_relationships")
@Getter
@Setter
@NoArgsConstructor
public class MemberRelationship {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "group_id", nullable = false)
    private GameGroup group;

    @ManyToOne(optional = false)
    @JoinColumn(name = "member_a_user_id", nullable = false)
    private AppUser memberA;

    @ManyToOne(optional = false)
    @JoinColumn(name = "member_b_user_id", nullable = false)
    private AppUser memberB;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "relationship_type", nullable = false)
    private RelationshipType relationshipType;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    public MemberRelationship(GameGroup group, AppUser memberA, AppUser memberB, RelationshipType relationshipType) {
        this.group = group;
        this.memberA = memberA;
        this.memberB = memberB;
        this.relationshipType = relationshipType;
    }
}
