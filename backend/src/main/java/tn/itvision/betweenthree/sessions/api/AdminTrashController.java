package tn.itvision.betweenthree.sessions.api;

import java.util.List;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import tn.itvision.betweenthree.common.api.ApiException;
import tn.itvision.betweenthree.sessions.domain.CardTrash;
import tn.itvision.betweenthree.sessions.repository.CardTrashRepository;

@RestController
@RequestMapping("/api/v1/admin/groups/{groupId}/trash")
@PreAuthorize("hasRole('ADMIN')")
public class AdminTrashController {

    private final CardTrashRepository cardTrashRepository;

    public AdminTrashController(CardTrashRepository cardTrashRepository) {
        this.cardTrashRepository = cardTrashRepository;
    }

    @GetMapping
    public List<TrashEntryResponse> listTrash(@PathVariable UUID groupId) {
        return cardTrashRepository.findByGroupId(groupId).stream()
            .map(t -> new TrashEntryResponse(t.getId(), t.getCard().getId(), t.getCard().getExternalKey(), t.getTrashedAt()))
            .toList();
    }

    @PostMapping("/{cardId}/restore")
    public ResponseEntity<Void> restore(@PathVariable UUID groupId, @PathVariable UUID cardId) {
        CardTrash entry = cardTrashRepository.findByGroupIdAndCardId(groupId, cardId)
            .orElseThrow(() -> ApiException.notFound("TRASH_ENTRY_NOT_FOUND", "This card is not currently in the trash"));

        cardTrashRepository.delete(entry);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/restore-bulk")
    public ResponseEntity<Void> restoreBulk(@PathVariable UUID groupId, @Valid @RequestBody RestoreBulkRequest request) {
        List<CardTrash> entries = cardTrashRepository.findByGroupIdAndCardIdIn(groupId, request.cardIds());
        cardTrashRepository.deleteAll(entries);
        return ResponseEntity.noContent().build();
    }

    private record TrashEntryResponse(UUID trashId, UUID cardId, String externalKey, java.time.Instant trashedAt) {
    }

    private record RestoreBulkRequest(@NotEmpty List<UUID> cardIds) {
    }
}
