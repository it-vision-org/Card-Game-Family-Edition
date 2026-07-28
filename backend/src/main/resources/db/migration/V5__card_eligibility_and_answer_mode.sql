-- Cards are drawn per-turn based on whose turn it is, so eligibility must be
-- explicit per card rather than the display-only targeting hints that were
-- never actually read by any client.

ALTER TABLE cards
    DROP COLUMN targeting_rule,
    DROP COLUMN targeting_config,
    ADD COLUMN eligible_player_public_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN answer_mode VARCHAR(50);
