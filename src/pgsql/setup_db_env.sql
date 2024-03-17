-- REQUIRED EXTENSIONS

CREATE EXTENSION IF NOT EXISTS plpython3u;

-- CREATING DATABASES 

DROP TABLE IF EXISTS envs CASCADE;

CREATE TABLE envs (
    id SERIAL PRIMARY KEY,
    window_height INTEGER CHECK (window_height > 0),
    window_width INTEGER CHECK (window_width > 0),
    window_title TEXT NOT NULL default 'App Window',
    target_framerate INTEGER CHECK (target_framerate > 0),
    running BOOLEAN default FALSE,
    frame_rendering_script_path TEXT NOT NULL
);

DROP TABLE IF EXISTS input_events CASCADE;

CREATE TABLE input_events (
    id SERIAL PRIMARY KEY,
    input_event_type INTEGER NOT NULL,
    key_code INTEGER NOT NULL,
    submitted_at TIMESTAMP DEFAULT now()
);

DROP TABLE IF EXISTS pixels CASCADE;

CREATE TABLE pixels (
    id SERIAL PRIMARY KEY,
    pos_x INTEGER NOT NULL CHECK (pos_x >= 0),
    pos_y INTEGER NOT NULL CHECK (pos_y >= 0),
    r INTEGER NOT NULL CHECK (r >= 0) default 255,
    g INTEGER NOT NULL CHECK (g >= 0) default 255,
    b INTEGER NOT NULL CHECK (b >= 0) default 255,
    env_id INTEGER REFERENCES envs(id) ON DELETE SET NULL
);

-- HANDLING INPUT EVENTS

CREATE OR REPLACE FUNCTION on_input_event(input_event_type INTEGER, key_code INTEGER)
RETURNS void AS $$
BEGIN
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION __internal_create_input_event_trigger()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM on_input_event(NEW.input_event_type, NEW.key_code);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_input_event_trigger
AFTER INSERT ON input_events
FOR EACH ROW
EXECUTE FUNCTION __internal_create_input_event_trigger();

-- RENDERING FRAMES

CREATE OR REPLACE FUNCTION on_render_frame()
RETURNS void AS $$
BEGIN
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _internal_run_render_frames_script_detached(command TEXT) RETURNS VOID AS $$
import subprocess

def run_executable_detached(cmd):
    try:
        subprocess.Popen(cmd)
    except Exception as e:
        raise Exception(f"Error running executable: {e}")

run_executable_detached(command)
$$ LANGUAGE plpython3u;

CREATE OR REPLACE FUNCTION _internal_start_render_frames_job(env_id INTEGER, pass TEXT)
RETURNS void AS $$
DECLARE
    cmd TEXT;
    db_conn_url TEXT;
    script_path TEXT;
BEGIN
    SELECT frame_rendering_script_path FROM envs WHERE id = env_id INTO script_path;

    SELECT 'postgresql://' || current_user || ':' || pass || '@' || (SELECT boot_val FROM pg_settings WHERE name='listen_addresses') || ':' || inet_server_port() || '/' || current_database() || '' INTO db_conn_url;

    cmd := 'python "' || script_path || '" --db-connection-url ' || db_conn_url || ' --env-id ' || env_id || '';
    
    PERFORM _internal_run_render_frames_script_detached(cmd);
END;
$$ LANGUAGE plpgsql;

-- DRAWING UTILS

CREATE OR REPLACE FUNCTION draw_rect(pos_x_val INTEGER, pos_y_val INTEGER, width_val INTEGER, height_val INTEGER, r_val INTEGER, g_val INTEGER, b_val INTEGER) RETURNS void AS $$
BEGIN
    UPDATE pixels SET r=r_val, g=g_val, b=b_val WHERE pos_x >= pos_x_val AND pos_x < (pos_x_val + width_val) AND pos_y >= pos_y_val AND pos_y < (pos_y_val + height_val);
END;
$$ LANGUAGE plpgsql;

-- STARTING ENV

CREATE OR REPLACE FUNCTION on_init()
RETURNS void AS $$
BEGIN
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _internal_init_env_pixels(width INTEGER, height INTEGER, env_id_val INTEGER) RETURNS void AS $$
DECLARE
    row_index INTEGER;
    col_index INTEGER;
BEGIN
    DELETE FROM pixels;
    EXECUTE 'ALTER SEQUENCE pixels_id_seq RESTART WITH 1';

    FOR row_index IN 0..height-1 LOOP
        FOR col_index IN 0..width-1 LOOP
            INSERT INTO pixels (id, pos_y, pos_x, env_id)
            VALUES (DEFAULT, row_index, col_index, env_id_val);
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION _internal_clear_events() RETURNS void AS $$
BEGIN
    DELETE FROM input_events;
    EXECUTE 'ALTER SEQUENCE input_events_id_seq RESTART WITH 1';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION start_env(env_id INTEGER, pass TEXT) RETURNS void AS $$
DECLARE
    window_width_val INTEGER;
    window_height_val INTEGER;
    already_running BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM envs WHERE running = TRUE) INTO already_running;
    
    IF already_running = TRUE THEN
        RETURN;
    END IF;

    SELECT window_width, window_height INTO window_width_val, window_height_val FROM envs WHERE id=env_id;

    UPDATE envs SET running=TRUE WHERE id=env_id;

    PERFORM _internal_clear_events();
    PERFORM _internal_init_env_pixels(window_width_val, window_height_val, env_id);
    PERFORM on_init();

    PERFORM _internal_start_render_frames_job(env_id, pass);
END;
$$ LANGUAGE plpgsql;

-- STOPPING envs

CREATE OR REPLACE FUNCTION stop_env() RETURNS void AS $$
BEGIN
    UPDATE envs SET running=FALSE;
END;
$$ LANGUAGE plpgsql;