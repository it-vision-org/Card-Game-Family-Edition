CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM (
    'PLAYER',
    'ADMIN'
);

CREATE TYPE card_type AS ENUM (
    'QUESTION',
    'CHALLENGE',
    'SURPRISE'
);

CREATE TYPE game_mode AS ENUM (
    'MIXED',
    'CATEGORY',
    'BEST_CARDS',
    'CUSTOM'
);

CREATE TYPE session_status AS ENUM (
    'DRAFT',
    'WAITING_FOR_PLAYERS',
    'READY',
    'IN_PROGRESS',
    'PAUSED',
    'COMPLETED',
    'CANCELLED'
);

CREATE TYPE session_card_status AS ENUM (
    'PENDING',
    'DRAWN',
    'COMPLETED',
    'SKIPPED',
    'REPLACED'
);

CREATE TABLE app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    public_id VARCHAR(20) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    role user_role NOT NULL DEFAULT 'PLAYER',
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE game_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    owner_id UUID NOT NULL REFERENCES app_users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE group_members (
    group_id UUID NOT NULL REFERENCES game_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    turn_position INTEGER,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (group_id, user_id)
);

CREATE TABLE card_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(80) NOT NULL UNIQUE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_key VARCHAR(100) NOT NULL UNIQUE,
    category_id UUID REFERENCES card_categories(id),
    card_type card_type NOT NULL,
    targeting_rule VARCHAR(50) NOT NULL,
    targeting_config JSONB NOT NULL DEFAULT '{}'::jsonb,

    is_best BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_skippable BOOLEAN NOT NULL DEFAULT TRUE,
    supports_scoring BOOLEAN NOT NULL DEFAULT FALSE,

    sensitivity_level SMALLINT NOT NULL DEFAULT 1,
    emotional_depth SMALLINT NOT NULL DEFAULT 1,

    minimum_players SMALLINT NOT NULL DEFAULT 2,
    maximum_players SMALLINT,

    requires_timer BOOLEAN NOT NULL DEFAULT FALSE,
    timer_seconds INTEGER,

    selection_weight INTEGER NOT NULL DEFAULT 100,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,

    CONSTRAINT ck_cards_sensitivity
        CHECK (sensitivity_level BETWEEN 1 AND 5),

    CONSTRAINT ck_cards_emotional_depth
        CHECK (emotional_depth BETWEEN 1 AND 5),

    CONSTRAINT ck_cards_player_count
        CHECK (
            minimum_players >= 1
            AND (
                maximum_players IS NULL
                OR maximum_players >= minimum_players
            )
        )
);

CREATE TABLE card_translations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    language_code VARCHAR(10) NOT NULL,
    title VARCHAR(200),
    text TEXT NOT NULL,
    instructions TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_card_translation
        UNIQUE (card_id, language_code)
);

CREATE TABLE game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES game_groups(id),
    created_by UUID NOT NULL REFERENCES app_users(id),

    session_code VARCHAR(12) NOT NULL UNIQUE,
    status session_status NOT NULL DEFAULT 'DRAFT',
    game_mode game_mode NOT NULL,
    scoring_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    requested_card_count INTEGER NOT NULL,
    completed_card_count INTEGER NOT NULL DEFAULT 0,

    current_turn_position INTEGER,
    random_seed BIGINT NOT NULL,
    version BIGINT NOT NULL DEFAULT 0,

    started_at TIMESTAMPTZ,
    paused_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT ck_sessions_card_count
        CHECK (requested_card_count > 0)
);

CREATE TABLE session_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_users(id),
    turn_position INTEGER NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_session_participant
        UNIQUE (session_id, user_id),

    CONSTRAINT uq_session_turn_position
        UNIQUE (session_id, turn_position)
);

CREATE TABLE session_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    card_id UUID NOT NULL REFERENCES cards(id),
    draw_order INTEGER NOT NULL,
    status session_card_status NOT NULL DEFAULT 'PENDING',
    active_player_id UUID REFERENCES session_participants(id),
    drawn_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_session_card
        UNIQUE (session_id, card_id),

    CONSTRAINT uq_session_draw_order
        UNIQUE (session_id, draw_order)
);

CREATE TABLE card_trash (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES game_groups(id) ON DELETE CASCADE,
    card_id UUID NOT NULL REFERENCES cards(id),
    source_session_id UUID NOT NULL REFERENCES game_sessions(id),
    trashed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    restored_at TIMESTAMPTZ,
    restored_by UUID REFERENCES app_users(id)
);

CREATE INDEX idx_cards_category
    ON cards(category_id);

CREATE INDEX idx_cards_best
    ON cards(is_best)
    WHERE is_best = TRUE
      AND is_active = TRUE
      AND deleted_at IS NULL;

CREATE INDEX idx_card_translations_language
    ON card_translations(language_code);

CREATE INDEX idx_sessions_code
    ON game_sessions(session_code);

CREATE INDEX idx_sessions_group_status
    ON game_sessions(group_id, status);

CREATE INDEX idx_session_cards_status
    ON session_cards(session_id, status);

CREATE UNIQUE INDEX uq_active_group_card_trash
    ON card_trash(group_id, card_id)
    WHERE restored_at IS NULL;