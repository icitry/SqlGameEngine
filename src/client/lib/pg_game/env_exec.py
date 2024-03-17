import signal
import sys
import threading
import time

from . import global_obj
from .db import DbConnectionManager
from .event import EventData, EventType


class EventThread(threading.Thread):
    def __init__(self, handlers_list, db_connection_url):
        super().__init__()

        self.handlers_list = handlers_list
        self.stop_event = threading.Event()
        self.lock = threading.Lock()

        self._db_manager = DbConnectionManager(db_connection_url)

    def _notify_handlers(self, data):
        with self.lock:
            for handler in self.handlers_list:
                handler(data)

    def start(self):
        self._db_manager.create_connection()
        super().start()

    def _query_for_event(self, event_data):
        query = "SELECT p.pos_x, p.pos_y, p.r, p.g, p.b, e.running FROM pixels p JOIN envs e ON p.env_id = e.id"
        self._db_manager.execute_query(query)
        res = self._db_manager.cursor.fetchall()

        for row in res:
            running = bool(row[5])

            if not running:
                event_data.event_type = EventType.EVENT_QUIT
                return

            event_data.event_type = EventType.EVENT_SET_FRAME
            event_data.frame_data.set_pixel_data(pos_x=int(row[0]),
                                                 pos_y=int(row[1]),
                                                 r=int(row[2]),
                                                 g=int(row[3]),
                                                 b=int(row[4]))

    def run(self):
        interval = 1 / global_obj.pg_config.target_fps
        last_call_time = time.time() - interval

        event_data = EventData()
        event_data.resize_frame(global_obj.pg_config.window_width, global_obj.pg_config.window_height)

        while not self.stop_event.is_set():
            current_time = time.time()
            elapsed_time = current_time - last_call_time

            if elapsed_time >= interval:
                self._query_for_event(event_data)
                self._notify_handlers(event_data)

                last_call_time = current_time
            else:
                time.sleep(interval - elapsed_time)

    def stop(self):
        self._db_manager.terminate_connection()
        self.stop_event.set()


class EnvState:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, db_connection_url):
        if not hasattr(self, '_initialized'):
            self._handlers = list()
            self._db_manager = DbConnectionManager(db_connection_url)
            self._event_thread = EventThread(self._handlers, db_connection_url)

            self._initialized = True

    def add_handler(self, handler):
        with self._event_thread.lock:
            self._handlers.append(handler)

    def submit_event(self, data):
        query = f'INSERT INTO input_events (input_event_type, key_code) ' \
                f'VALUES ({data.event_type.value}, {data.key_code})'

        self._db_manager.execute_query(query, should_commit=True)

        if data.event_type == EventType.EVENT_QUIT:
            self.stop_exec()
            sys.exit(0)

    def _check_env_running(self):
        query = f'select running from envs where id={global_obj.pg_config._env_id}'
        self._db_manager.execute_query(query)

        res = self._db_manager.cursor.fetchone()

        is_env_running = bool(res[0])

        if not is_env_running:
            raise RuntimeError('Specified env is not running. Cannot connect to process.')

    def _terminate_signal_handler(self, sig, frame):
        self.stop_exec()
        sys.exit(0)

    def start_exec(self):
        self._db_manager.create_connection()
        self._check_env_running()

        self._event_thread.start()

        signal.signal(signal.SIGINT, self._terminate_signal_handler)
        signal.signal(signal.SIGTERM, self._terminate_signal_handler)

    def stop_exec(self):
        self._db_manager.terminate_connection()
        self._event_thread.stop()
        self._event_thread.join()


def init_env():
    if global_obj.env_state is None:
        global_obj.env_state = EnvState(global_obj.pg_config._db_connection_url)

    global_obj.env_state.start_exec()


def stop_env():
    if global_obj.env_state is None:
        return
    global_obj.env_state.stop_exec()
    global_obj.env_state = None
