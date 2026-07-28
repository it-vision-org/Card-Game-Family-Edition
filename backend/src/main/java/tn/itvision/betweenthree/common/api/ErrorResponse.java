package tn.itvision.betweenthree.common.api;

import java.time.Instant;
import java.util.List;

public record ErrorResponse(
    Instant timestamp,
    int status,
    String code,
    String message,
    List<FieldError> fieldErrors
) {

    public record FieldError(String field, String message) {
    }

    public static ErrorResponse of(int status, String code, String message) {
        return new ErrorResponse(Instant.now(), status, code, message, List.of());
    }

    public static ErrorResponse of(int status, String code, String message, List<FieldError> fieldErrors) {
        return new ErrorResponse(Instant.now(), status, code, message, fieldErrors);
    }
}
