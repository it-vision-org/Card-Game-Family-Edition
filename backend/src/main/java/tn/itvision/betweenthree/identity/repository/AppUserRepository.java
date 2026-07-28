package tn.itvision.betweenthree.identity.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import tn.itvision.betweenthree.identity.domain.AppUser;

public interface AppUserRepository extends JpaRepository<AppUser, UUID> {

    Optional<AppUser> findByPublicId(String publicId);

    boolean existsByPublicId(String publicId);
}
