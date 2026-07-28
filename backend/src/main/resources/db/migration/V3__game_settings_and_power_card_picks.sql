ALTER TABLE session_participant_power_cards
    DROP CONSTRAINT uq_participant_power_card;

CREATE TABLE game_settings (
    id UUID PRIMARY KEY,
    power_cards_per_player SMALLINT NOT NULL DEFAULT 2,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES app_users(id),

    CONSTRAINT ck_game_settings_power_cards_per_player
        CHECK (power_cards_per_player > 0)
);

-- Single well-known row: the app always reads/writes this exact id rather
-- than "the first row", so there is never ambiguity about which settings
-- row is authoritative.
INSERT INTO game_settings (id, power_cards_per_player)
VALUES ('00000000-0000-0000-0000-000000000001', 2);
