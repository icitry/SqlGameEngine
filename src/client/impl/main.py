import os
import tkinter as tk
from functools import partial

import pg_game
from PIL import Image, ImageTk

from util import init_fps_counter, start_fps_counter, stop_fps_counter


class RemoteEventHandler(pg_game.EventHandlerBase):
    def __init__(self, window, canvas, frame_img_data, frame_img, signal_render_frame_cb):
        self._window = window
        self._canvas = canvas
        self._frame_img_data = frame_img_data
        self._frame_img = frame_img
        self._signal_render_frame_cb = signal_render_frame_cb

    def _set_frame(self, frame: pg_game.FrameData):
        self._frame_img_data.putdata(frame.packed_pixels)
        self._frame_img.paste(self._frame_img_data)
        self._canvas.create_image(0, 0, image=self._frame_img, anchor=tk.NW)
        self._signal_render_frame_cb()

    def _quit(self):
        self._window.destroy()
        os._exit(0)
        print('QUIT')

    def __call__(self, data: pg_game.EventData):
        if data.event_type == pg_game.EventType.EVENT_QUIT:
            self._quit()

        if data.event_type == pg_game.EventType.EVENT_SET_FRAME:
            self._set_frame(data.frame_data)


def on_key_event(data: pg_game.EventData, event):
    data.key_code = event.keysym_num
    pg_game.submit_event(data)


def on_close_window(window):
    window.destroy()
    os._exit(0)


def main():
    pg_game.init_config(db_connection_url='postgresql://postgres:pass@localhost:6070/sql_game')

    window = tk.Tk()
    window.width = pg_game.global_obj.pg_config.window_width
    window.height = pg_game.global_obj.pg_config.window_height
    window.geometry(f"{window.width}x{window.height}")
    window.title(pg_game.global_obj.pg_config.window_title)

    window.bind("<Key>", partial(pg_game.submit_event, pg_game.EventData(event_type=pg_game.EventType.EVENT_KEY_CLICK)))
    window.bind("<KeyPress>", partial(on_key_event, pg_game.EventData(event_type=pg_game.EventType.EVENT_KEY_PRESS)))
    window.bind("<KeyRelease>",
                partial(on_key_event, pg_game.EventData(event_type=pg_game.EventType.EVENT_KEY_RELEASE)))

    window.protocol("WM_DELETE_WINDOW", partial(on_close_window, window))

    frame_img_data = Image.new(
        'RGB',
        (pg_game.global_obj.pg_config.window_width, pg_game.global_obj.pg_config.window_height),
        color='black')
    frame_img = ImageTk.PhotoImage(frame_img_data)

    canvas = tk.Canvas(window, bg='black', highlightthickness=0)
    canvas.create_image(0, 0, image=frame_img, anchor=tk.NW)
    canvas.pack(fill="both", expand=True)

    signal_render_frame_cb = init_fps_counter()

    pg_game.add_event_handler(RemoteEventHandler(window, canvas, frame_img_data, frame_img, signal_render_frame_cb))

    pg_game.init_env()

    start_fps_counter()

    window.mainloop()

    stop_fps_counter()

    pg_game.stop_env()


if __name__ == '__main__':
    main()
