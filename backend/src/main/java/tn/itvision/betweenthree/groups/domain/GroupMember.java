package tn.itvision.betweenthree.groups.domain;

import java.time.Instant;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import tn.itvision.betweenthree.identity.domain.AppUser;

@Entity
@Table(name = "group_members")
@Getter
@Setter
@NoArgsConstructor
public class GroupMember {

    @EmbeddedId
    private GroupMemberId id;

    @ManyToOne(optional = false)
    @MapsId("groupId")
    @JoinColumn(name = "group_id")
    private GameGroup group;

    @ManyToOne(optional = false)
    @MapsId("userId")
    @JoinColumn(name = "user_id")
    private AppUser user;

    @Column(name = "turn_position")
    private Integer turnPosition;

    @CreationTimestamp
    @Column(name = "joined_at", nullable = false, updatable = false)
    private Instant joinedAt;

    public GroupMember(GameGroup group, AppUser user, Integer turnPosition) {
        this.group = group;
        this.user = user;
        this.turnPosition = turnPosition;
        this.id = new GroupMemberId(group.getId(), user.getId());
    }
}
