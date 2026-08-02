-- Distinguishes a participant who joined a session themselves by entering the
-- session code on their own device/login (true multi-device play) from one
-- who was added by another player via the "same phone" quick-add flow.
-- A session is genuinely multi-device only if at least one participant has
-- this set to true.
ALTER TABLE session_participants
    ADD COLUMN joined_via_code BOOLEAN NOT NULL DEFAULT false;
