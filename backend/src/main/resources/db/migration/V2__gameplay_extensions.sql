ALTER TABLE game_sessions
    ADD COLUMN category_code VARCHAR(80);

CREATE TYPE relationship_type AS ENUM (
    'PARTNER',
    'PARENT_CHILD',
    'PARTNER_PARENT'
);

CREATE TYPE power_card_effect AS ENUM (
    'WHISPER',
    'DECLINE_TO_ANSWER',
    'MIRROR',
    'FULL_STORY',
    'CHANGE_QUESTION',
    'EVERYONE_ANSWERS',
    'WORD_FROM_HEART',
    'NO_DIPLOMACY'
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    device_info VARCHAR(255),
    issued_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE member_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES game_groups(id) ON DELETE CASCADE,
    member_a_user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    member_b_user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    relationship_type relationship_type NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_member_relationship_order
        CHECK (member_a_user_id < member_b_user_id),

    CONSTRAINT uq_member_relationship
        UNIQUE (group_id, member_a_user_id, member_b_user_id)
);

CREATE TABLE power_card_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(60) NOT NULL UNIQUE,
    effect_type power_card_effect NOT NULL UNIQUE,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    max_uses_per_session SMALLINT NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_power_card_max_uses
        CHECK (max_uses_per_session > 0)
);

CREATE TABLE session_participant_power_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    participant_id UUID NOT NULL REFERENCES session_participants(id) ON DELETE CASCADE,
    power_card_definition_id UUID NOT NULL REFERENCES power_card_definitions(id),
    target_participant_id UUID REFERENCES session_participants(id),
    used_on_session_card_id UUID REFERENCES session_cards(id),
    granted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    used_at TIMESTAMPTZ,

    CONSTRAINT uq_participant_power_card
        UNIQUE (session_id, participant_id, power_card_definition_id)
);

CREATE TABLE score_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    session_card_id UUID REFERENCES session_cards(id),
    participant_id UUID NOT NULL REFERENCES session_participants(id) ON DELETE CASCADE,
    points INTEGER NOT NULL,
    reason_code VARCHAR(50) NOT NULL,
    note VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_score_events_points
        CHECK (points <> 0)
);

CREATE INDEX idx_refresh_tokens_user
    ON refresh_tokens(user_id);

CREATE INDEX idx_refresh_tokens_active
    ON refresh_tokens(expires_at)
    WHERE revoked_at IS NULL;

CREATE INDEX idx_member_relationships_group
    ON member_relationships(group_id);

CREATE INDEX idx_participant_power_cards_session
    ON session_participant_power_cards(session_id);

CREATE INDEX idx_participant_power_cards_participant
    ON session_participant_power_cards(participant_id);

CREATE INDEX idx_score_events_session
    ON score_events(session_id);

CREATE INDEX idx_score_events_participant
    ON score_events(participant_id);
