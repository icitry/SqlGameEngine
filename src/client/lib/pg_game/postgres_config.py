from .db import DbConnectionManager


class PGConfig:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, db_connection_url):
        if not hasattr(self, '_initialized'):
            self._db_connection_url = db_connection_url
            self._get_env_parameters_from_server()

            self._initialized = True

    def _get_env_parameters_from_server(self):
        db_manager = DbConnectionManager(self._db_connection_url)
        db_manager.create_connection()
        db_manager.execute_query(
            f'SELECT id, window_height, window_width, window_title, target_framerate FROM envs WHERE running = TRUE')

        res = db_manager.cursor.fetchone()

        if res is None:
            raise RuntimeError('No running env found.')
        self._env_id = int(res[0])
        self._window_width = int(res[1])
        self._window_height = int(res[2])
        self._window_title = res[3]
        self._target_fps = int(res[4])

        db_manager.terminate_connection()

    @property
    def window_width(self):
        return self._window_width if self._window_width is not None else 0

    @property
    def window_height(self):
        return self._window_height if self._window_height is not None else 0

    @property
    def window_title(self):
        return self._window_title if self._window_title is not None else ''

    @property
    def target_fps(self):
        return self._target_fps if self._target_fps is not None else 0
