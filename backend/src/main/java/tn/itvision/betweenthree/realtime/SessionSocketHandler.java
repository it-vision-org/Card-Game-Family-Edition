package tn.itvision.betweenthree.realtime;

import java.io.IOException;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import tools.jackson.databind.json.JsonMapper;

import lombok.extern.slf4j.Slf4j;

/**
 * Plain JSON WebSocket fan-out per session code: every device that joined a
 * session connects to {@code /ws/sessions/{sessionCode}} and receives a
 * {"type", "sessionCode", "payload"} envelope after each state-changing
 * action, instead of polling the REST API.
 */
@Slf4j
@Component
public class SessionSocketHandler extends TextWebSocketHandler {

    private final Map<String, Set<WebSocketSession>> sessionsByCode = new ConcurrentHashMap<>();
    private final JsonMapper objectMapper;

    public SessionSocketHandler(JsonMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        String sessionCode = extractSessionCode(session);
        if (sessionCode == null) {
            closeQuietly(session, CloseStatus.BAD_DATA);
            return;
        }

        sessionsByCode
            .computeIfAbsent(sessionCode, key -> new CopyOnWriteArraySet<>())
            .add(session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        String sessionCode = extractSessionCode(session);
        if (sessionCode != null) {
            Set<WebSocketSession> sessions = sessionsByCode.get(sessionCode);
            if (sessions != null) {
                sessions.remove(session);
            }
        }
    }

    public void broadcast(String sessionCode, String eventType, Object payload) {
        Set<WebSocketSession> sessions = sessionsByCode.get(sessionCode);
        if (sessions == null || sessions.isEmpty()) {
            return;
        }

        try {
            String json = objectMapper.writeValueAsString(new Envelope(eventType, sessionCode, payload));
            TextMessage message = new TextMessage(json);
            for (WebSocketSession session : sessions) {
                if (session.isOpen()) {
                    session.sendMessage(message);
                }
            }
        } catch (Exception e) {
            log.warn("Failed to broadcast session update for {}", sessionCode, e);
        }
    }

    private String extractSessionCode(WebSocketSession session) {
        if (session.getUri() == null) {
            return null;
        }
        String path = session.getUri().getPath();
        String[] segments = path.split("/");
        return segments.length > 0 ? segments[segments.length - 1] : null;
    }

    private void closeQuietly(WebSocketSession session, CloseStatus status) {
        try {
            session.close(status);
        } catch (IOException ignored) {
            // best effort
        }
    }

    private record Envelope(String type, String sessionCode, Object payload) {
    }
}
