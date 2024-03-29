-- Generated template for Snake Game.
-- Make use of the provided functions to build your game.
-- Once done, use ** \i "D:\Github\SQLGame\src\pgsql" ** to load your game into the database.
-- Afterwards, call ** select start_game(<env_id>); ** with the id of the desired configuration.


-- These are here to make copy-pasting easier. 
-- I don't want to store these and query for them 
-- as it's too slow. 

-- CELL SIZE = 10px

-- RGB Values for the tiles (cells)
-- BG = 119, 209, 212
-- REWARD = 204, 6, 29
-- SNAKE CELL = 0, 179, 9

DROP TABLE IF EXISTS snake_game_state CASCADE;

CREATE TABLE snake_game_state (
    id SERIAL PRIMARY KEY,
    running BOOLEAN default FALSE,
    is_over BOOLEAN default FALSE,
    cell_size INTEGER default 1,
    curr_reward_pos_x INTEGER,
    curr_reward_pos_y INTEGER,
    snake_velocity_x INTEGER default 0,
    snake_velocity_y INTEGEr default 0
);

DROP TABLE IF EXISTS snake_cells CASCADE;

CREATE TABLE snake_cells (
    id SERIAL PRIMARY KEY,
    pos_x INTEGER,
    pos_y INTEGER,
    snake_pos INTEGER default 0
);

CREATE OR REPLACE FUNCTION _get_random_val(interval_start INTEGER, interval_end INTEGER, step INTEGER)
RETURNS INTEGER AS $$
DECLARE
    num_possible_values INTEGER;
    random_index INTEGER;
    random_value INTEGER;
BEGIN
    num_possible_values := (interval_end - interval_start) / step + 1;

    random_index := floor(random() * num_possible_values);

    random_value := interval_start + random_index * step;

    RETURN random_value;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _draw_reward_graphic(r_val INTEGER, g_val INTEGER, b_val INTEGER)
RETURNS void AS $$
DECLARE 
    query_text TEXT;
BEGIN
    query_text := 'SELECT draw_rect(curr_reward_pos_x, curr_reward_pos_y, 10, 10, $1, $2, $3) FROM snake_game_state';
    EXECUTE query_text USING r_val, g_val, b_val;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _draw_snake_graphic(r_val INTEGER, g_val INTEGER, b_val INTEGER)
RETURNS void AS $$
DECLARE 
    query_text TEXT;
BEGIN
    query_text := 'SELECT draw_rect(pos_x, pos_y, 10, 10, $1, $2, $3) FROM snake_cells';
    EXECUTE query_text USING r_val, g_val, b_val;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _start_game_if_not_running()
RETURNS void AS $$
DECLARE
    running_val BOOLEAN;
    is_over_val BOOLEAN;
BEGIN
    SELECT running, is_over INTO running_val, is_over_val FROM snake_game_state LIMIT 1;
    IF running_val = TRUE AND is_over_val = FALSE THEN
        RETURN;
    END IF;

    IF is_over_val = TRUE THEN
        -- Clear previous graphics.
        PERFORM _draw_reward_graphic(119, 209, 212);
        PERFORM _draw_snake_graphic(119, 209, 212);

        DELETE FROM snake_cells;
        INSERT INTO snake_cells (pos_x, pos_y) VALUES (180, 180);

        UPDATE snake_game_state SET running = TRUE, is_over = FALSE, curr_reward_pos_x = (SELECT _get_random_val(10, 380, 10)), curr_reward_pos_y = (SELECT _get_random_val(10, 380, 10)), snake_velocity_x = 1, snake_velocity_y = 0;
        RETURN; 
    END IF;

    IF running_val = FALSE THEN
        UPDATE snake_game_state SET running = TRUE;
        RETURN;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _move_snake()
RETURNS void AS $$
DECLARE
    dx INTEGER;
    dy INTEGER;
    snake_len INTEGER;
BEGIN
    SELECT MAX(snake_pos) + 1 INTO snake_len FROM snake_cells;
    SELECT snake_velocity_x, snake_velocity_y INTO dx, dy FROM snake_game_state LIMIT 1;
    UPDATE snake_cells AS s1 SET pos_x = (CASE WHEN s2.pos_x + (dx * 10) < 10 THEN 380 WHEN s2.pos_x + (dx * 10) > 380 THEN 10 ELSE s2.pos_x + (dx * 10) END), pos_y = (CASE WHEN s2.pos_y + (dy * 10) < 10 THEN 380 WHEN s2.pos_y + (dy * 10) > 380 THEN 10 ELSE s2.pos_y + (dy * 10) END) FROM snake_cells AS s2 WHERE s1.snake_pos = snake_len - 1 AND s2.snake_pos = 0;
    UPDATE snake_cells SET snake_pos = (snake_pos + 1) % snake_len; -- Move each cell
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _check_collision_with_self()
RETURNS void AS $$
DECLARE
    has_overlap BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM snake_cells s1 JOIN snake_cells s2 ON s1.pos_x = s2.pos_x AND s1.pos_y = s2.pos_y WHERE s1.id <> s2.id) INTO has_overlap;
    IF has_overlap = TRUE THEN
        UPDATE snake_game_state SET running = FALSE, snake_velocity_x = 0, snake_velocity_y = 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _check_collision_with_reward()
RETURNS void AS $$
DECLARE
    snake_head_pos_x INTEGER;
    snake_head_pos_y INTEGER;
    reward_pos_x INTEGER;
    reward_pos_y INTEGER;
    snake_tail_pos_x INTEGER;
    snake_tail_pos_y INTEGER;
    dx INTEGER;
    dy INTEGER;
    snake_len INTEGER;
BEGIN
    SELECT curr_reward_pos_x, curr_reward_pos_y INTO reward_pos_x, reward_pos_y FROM snake_game_state LIMIT 1;
    SELECT pos_x, pos_y INTO snake_head_pos_x, snake_head_pos_y FROM snake_cells WHERE snake_pos = 0;

    IF snake_head_pos_x = reward_pos_x AND snake_head_pos_y = reward_pos_y THEN
        SELECT MAX(snake_pos) + 1 INTO snake_len FROM snake_cells;
        SELECT snake_velocity_x, snake_velocity_y INTO dx, dy FROM snake_game_state LIMIT 1;
        SELECT pos_x, pos_y INTO snake_tail_pos_x, snake_tail_pos_y FROM snake_cells WHERE snake_pos = snake_len - 1;

        INSERT INTO snake_cells (pos_x, pos_y, snake_pos) VALUES (snake_tail_pos_x - (dx * 10), snake_tail_pos_y - (dy * 10), snake_len);

        UPDATE snake_game_state SET curr_reward_pos_x = (SELECT _get_random_val(10, 380, 10)), curr_reward_pos_y = (SELECT _get_random_val(10, 380, 10));
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _check_collision_with_self()
RETURNS void AS $$
DECLARE
    has_overlap BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM snake_cells s1 JOIN snake_cells s2 ON s1.pos_x = s2.pos_x AND s1.pos_y = s2.pos_y WHERE s1.id <> s2.id) INTO has_overlap;
    IF has_overlap = TRUE THEN
        UPDATE snake_game_state SET is_over = 1, snake_velocity_x = 0, snake_velocity_y = 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION on_init()
RETURNS void AS $$
DECLARE 
    curr_reward_pos_x_val INTEGER;
    curr_reward_pos_y_val INTEGER;
BEGIN
    -- Runs before the game loop begins.
    UPDATE pixels SET r = 119, g = 209, b = 212; -- BG Color

    SELECT _get_random_val(10, 380, 10) INTO curr_reward_pos_x_val;
    SELECT _get_random_val(10, 380, 10) INTO curr_reward_pos_y_val;

    DELETE FROM snake_game_state;
    DELETE FROM snake_cells;

    INSERT INTO snake_game_state (cell_size, curr_reward_pos_x, curr_reward_pos_y, snake_velocity_x, snake_velocity_y) VALUES (10, curr_reward_pos_x_val, curr_reward_pos_y_val, 1, 0);
    INSERT INTO snake_cells (pos_x, pos_y) VALUES (180, 180);

    PERFORM draw_rect(curr_reward_pos_x_val, curr_reward_pos_y_val, 10, 10, 204, 6, 29);
    PERFORM draw_rect(180, 180, 10, 10, 0, 179, 9);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION on_input_event(input_event_type INTEGER, key_code INTEGER)
RETURNS void AS $$
BEGIN
    -- Handle user event here.
    IF input_event_type = 3 THEN -- EVENT_KEY_PRESS
        IF key_code = 32 THEN -- SPACE
            PERFORM _start_game_if_not_running();
        END IF;

        IF key_code = 119 OR key_code = 87 THEN -- w or W
            UPDATE snake_game_state SET snake_velocity_x = 0, snake_velocity_y = -1 WHERE running = TRUE;
        END IF;

        IF key_code = 115 OR key_code = 83 THEN -- s or S
            UPDATE snake_game_state SET snake_velocity_x = 0, snake_velocity_y = 1 WHERE running = TRUE;
        END IF;

        IF key_code = 97 OR key_code = 65 THEN -- a or A
            UPDATE snake_game_state SET snake_velocity_x = -1, snake_velocity_y = 0 WHERE running = TRUE;
        END IF;

        IF key_code = 100 OR key_code = 68 THEN -- d or D
            UPDATE snake_game_state SET snake_velocity_x = 1, snake_velocity_y = 0 WHERE running = TRUE;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION on_render_frame()
RETURNS void AS $$
DECLARE
    running_val BOOLEAN;
    is_over_val BOOLEAN;
BEGIN
    -- Render frame here.

    SELECT running, is_over INTO running_val, is_over_val FROM snake_game_state LIMIT 1;
    IF running_val = FALSE OR is_over_val = TRUE THEN
        RETURN;
    END IF;
    
    -- Clear previous graphics.
    PERFORM _draw_reward_graphic(119, 209, 212);
    PERFORM _draw_snake_graphic(119, 209, 212);

    PERFORM _move_snake();
    PERFORM _check_collision_with_self();
    PERFORM _check_collision_with_reward();

    -- Draw new graphics.
    PERFORM _draw_reward_graphic(204, 6, 29);
    PERFORM _draw_snake_graphic(0, 179, 9);
END;
$$ LANGUAGE plpgsql;
