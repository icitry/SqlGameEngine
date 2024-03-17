INSERT INTO envs (window_height, window_width, window_title, target_framerate, frame_rendering_script_path)
VALUES (400, 400, 'Snake', 5, 'path\to\frame_rendering.py');

-- Select the game environment to run the game in and start execution. Needs current user password.
-- SELECT start_env(env_id, '<password>'); 

-- Stop the currently running game environment.
-- SELECT stop_env(); 