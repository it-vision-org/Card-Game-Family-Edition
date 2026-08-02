package tn.itvision.betweenthree.voice.api.dto;

public record VoiceTokenResponse(
    String url,
    String token,
    String roomName
) {
}
