-- Players can author their own questions from the "Cards" screen. NULL means
-- the card is part of the original curated/seeded catalog.
ALTER TABLE cards
    ADD COLUMN created_by_user_id UUID REFERENCES app_users(id);
