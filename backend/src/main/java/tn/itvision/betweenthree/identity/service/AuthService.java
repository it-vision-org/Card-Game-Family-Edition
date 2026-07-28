package tn.itvision.betweenthree.identity.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.regex.Pattern;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.common.security.AppSecurityProperties;
import tn.itvision.betweenthree.common.security.JwtTokenService;
import tn.itvision.betweenthree.identity.api.dto.AuthResponse;
import tn.itvision.betweenthree.identity.api.dto.UserSummary;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.identity.domain.RefreshToken;
import tn.itvision.betweenthree.identity.repository.AppUserRepository;
import tn.itvision.betweenthree.identity.repository.RefreshTokenRepository;

@Service
public class AuthService {

    private static final Pattern PIN_PATTERN = Pattern.compile("^\\d{4,6}$");

    private final AppUserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenService jwtTokenService;
    private final AppSecurityProperties securityProperties;
    private final SecureRandom secureRandom = new SecureRandom();

    public AuthService(
        AppUserRepository userRepository,
        RefreshTokenRepository refreshTokenRepository,
        PasswordEncoder passwordEncoder,
        JwtTokenService jwtTokenService,
        AppSecurityProperties securityProperties
    ) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenService = jwtTokenService;
        this.securityProperties = securityProperties;
    }

    @Transactional
    public AuthResponse login(String publicId, String pin, String deviceInfo) {
        AppUser user = userRepository.findByPublicId(publicId.trim().toUpperCase())
            .filter(AppUser::isEnabled)
            .orElseThrow(() -> ApiException.unauthorized("INVALID_CREDENTIALS", "Identifiant ou code incorrect"));

        if (user.getPasswordHash() == null || !passwordEncoder.matches(pin, user.getPasswordHash())) {
            throw ApiException.unauthorized("INVALID_CREDENTIALS", "Identifiant ou code incorrect");
        }

        return issueTokenPair(user, deviceInfo);
    }

    @Transactional
    public AuthResponse refresh(String refreshTokenPlain, String deviceInfo) {
        String hash = hash(refreshTokenPlain);
        RefreshToken token = refreshTokenRepository.findByTokenHash(hash)
            .filter(t -> t.isActive(Instant.now()))
            .orElseThrow(() -> ApiException.unauthorized("INVALID_REFRESH_TOKEN", "Refresh token invalide ou expiré"));

        token.setRevokedAt(Instant.now());
        return issueTokenPair(token.getUser(), deviceInfo);
    }

    @Transactional
    public void logout(String refreshTokenPlain) {
        refreshTokenRepository.findByTokenHash(hash(refreshTokenPlain))
            .ifPresent(token -> token.setRevokedAt(Instant.now()));
    }

    @Transactional
    public void changePin(AppUser user, String currentPin, String newPin) {
        if (user.getPasswordHash() == null || !passwordEncoder.matches(currentPin, user.getPasswordHash())) {
            throw ApiException.badRequest("INVALID_CURRENT_PIN", "الرمز السري الحالي غير صحيح");
        }
        if (!PIN_PATTERN.matcher(newPin).matches()) {
            throw ApiException.badRequest("INVALID_PIN_FORMAT", "الرمز السري لازم يكون بين 4 و6 أرقام");
        }

        user.setPasswordHash(passwordEncoder.encode(newPin));
        userRepository.save(user);
    }

    private AuthResponse issueTokenPair(AppUser user, String deviceInfo) {
        String accessToken = jwtTokenService.issueAccessToken(
            user.getId(),
            user.getPublicId(),
            user.getDisplayName(),
            user.getRole().name()
        );

        String refreshPlain = generateOpaqueToken();
        Instant now = Instant.now();

        RefreshToken refreshToken = new RefreshToken(
            user,
            hash(refreshPlain),
            deviceInfo,
            now,
            now.plus(securityProperties.refreshTokenExpiration())
        );
        refreshTokenRepository.save(refreshToken);

        return new AuthResponse(
            accessToken,
            refreshPlain,
            securityProperties.accessTokenExpiration().toSeconds(),
            UserSummary.from(user)
        );
    }

    private String generateOpaqueToken() {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hash(String value) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}
