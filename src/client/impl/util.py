import sys
import threading
import time
from typing import Optional


class FPSCounterThread(threading.Thread):
    def __init__(self):
        super().__init__()
        self.frame_times = []
        self.stop_event = threading.Event()
        self.lock = threading.Lock()

    def run(self):
        while not self.stop_event.is_set():
            current_fps = fps_counter.calculate_fps()
            sys.stdout.write(f"\rFPS: {current_fps}")
            sys.stdout.flush()
            time.sleep(1.0)

    def stop(self):
        self.stop_event.set()

    def update(self):
        with self.lock:
            current_time = time.time()
            self.frame_times.append(current_time)

            # Keep only the last 100 frame times to calculate average FPS
            self.frame_times = self.frame_times[-100:]

    def calculate_fps(self):
        with self.lock:
            if len(self.frame_times) < 2:
                return 0.0
            frame_times_diff = [self.frame_times[i] - self.frame_times[i - 1] for i in range(1, len(self.frame_times))]
            average_frame_time = sum(frame_times_diff) / len(frame_times_diff)
            fps = 1.0 / average_frame_time
            return fps


fps_counter: Optional[FPSCounterThread] = None


def init_fps_counter():
    global fps_counter
    fps_counter = FPSCounterThread()
    return fps_counter.update


def start_fps_counter():
    if fps_counter is None:
        return

    fps_counter.start()


def stop_fps_counter():
    if fps_counter is None:
        return

    fps_counter.stop()
    fps_counter.join()
