package tn.itvision.betweenthree.identity.api;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import tn.itvision.betweenthree.common.security.CurrentUserProvider;
import tn.itvision.betweenthree.identity.api.dto.AuthResponse;
import tn.itvision.betweenthree.identity.api.dto.ChangePinRequest;
import tn.itvision.betweenthree.identity.api.dto.LoginRequest;
import tn.itvision.betweenthree.identity.api.dto.LogoutRequest;
import tn.itvision.betweenthree.identity.api.dto.RefreshRequest;
import tn.itvision.betweenthree.identity.api.dto.UserSummary;
import tn.itvision.betweenthree.identity.domain.AppUser;
import tn.itvision.betweenthree.identity.service.AuthService;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    private final CurrentUserProvider currentUserProvider;

    public AuthController(AuthService authService, CurrentUserProvider currentUserProvider) {
        this.authService = authService;
        this.currentUserProvider = currentUserProvider;
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request.publicId(), request.pin(), request.deviceInfo());
    }

    @PostMapping("/refresh")
    public AuthResponse refresh(@Valid @RequestBody RefreshRequest request) {
        return authService.refresh(request.refreshToken(), request.deviceInfo());
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@Valid @RequestBody LogoutRequest request) {
        authService.logout(request.refreshToken());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/me")
    public UserSummary me(@AuthenticationPrincipal Jwt jwt) {
        return UserSummary.from(currentUserProvider.require(jwt));
    }

    @PatchMapping("/me/pin")
    public ResponseEntity<Void> changePin(@Valid @RequestBody ChangePinRequest request, @AuthenticationPrincipal Jwt jwt) {
        AppUser user = currentUserProvider.require(jwt);
        authService.changePin(user, request.currentPin(), request.newPin());
        return ResponseEntity.noContent().build();
    }
}
