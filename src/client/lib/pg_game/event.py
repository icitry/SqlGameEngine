from enum import IntEnum

from . import global_obj


class EventType(IntEnum):
    # Program loop events.
    EVENT_SET_FRAME = 0,
    EVENT_QUIT = 1,

    # I / O events.
    EVENT_KEY_CLICK = 2
    EVENT_KEY_PRESS = 3
    EVENT_KEY_RELEASE = 4


class PixelData:
    def __init__(self, pos_x: int = 0,
                 pos_y: int = 0,
                 r: int = 0,
                 g: int = 0,
                 b: int = 0):
        self.pos_x = pos_x
        self.pos_y = pos_y
        self.r = r
        self.g = g
        self.b = b

    @property
    def packed(self):
        return self.r, self.g, self.b


class FrameData:
    pixels: list[list[PixelData]]

    def __init__(self, width, height):
        self.resize(width, height)

    def resize(self, width, height):
        self.pixels = [[PixelData() for _ in range(width)] for _ in range(height)]

    def set_pixel_data(self, pos_x, pos_y, r, g, b) -> bool:
        if len(self.pixels) < 1:
            return False

        if len(self.pixels[0]) < 1:
            return False

        if pos_y >= len(self.pixels) or pos_x >= len(self.pixels[0]):
            return False

        self.pixels[pos_y][pos_x].r = r
        self.pixels[pos_y][pos_x].g = g
        self.pixels[pos_y][pos_x].b = b

    @property
    def packed_pixels(self):
        return [pixel.packed for row in self.pixels for pixel in row]

    @property
    def width(self):
        return global_obj.pg_config.window_width

    @property
    def height(self):
        return global_obj.pg_config.window_height


class EventData:
    def __init__(self, event_type: EventType = EventType.EVENT_QUIT, key_code: int = 0, frame_data: FrameData = None):
        self.event_type = event_type
        self.key_code = key_code
        self.frame_data = frame_data

    def resize_frame(self, width, height):
        if self.frame_data is None:
            self.frame_data = FrameData(width, height)
        else:
            self.frame_data.resize(width, height)


class EventHandlerBase:
    def __call__(self, data: EventData):
        raise NotImplementedError("Handler must implement __call__ method.")


def add_event_handler(handler: EventHandlerBase):
    global_obj.env_state.add_handler(handler)


def submit_event(data: EventData):
    global_obj.env_state.submit_event(data)
