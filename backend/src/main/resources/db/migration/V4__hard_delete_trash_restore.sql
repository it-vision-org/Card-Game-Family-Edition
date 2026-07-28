-- Restoring a card from the trash now deletes the row outright instead of
-- soft-restoring it (a trashed card either has a row here, or it doesn't).

DROP INDEX uq_active_group_card_trash;

ALTER TABLE card_trash
    DROP COLUMN restored_at,
    DROP COLUMN restored_by;

CREATE UNIQUE INDEX uq_group_card_trash
    ON card_trash(group_id, card_id);
