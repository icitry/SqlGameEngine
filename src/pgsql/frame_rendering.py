import argparse
import signal
import sys
import time

import psycopg2
from psycopg2._psycopg import connection, cursor

conn: connection
cur: cursor
args: list[str]


def check_terminate_flag():
    global cur
    cur.execute(f"SELECT EXISTS (SELECT 1 from envs WHERE running = TRUE)")
    is_running = cur.fetchone()[0]

    return not is_running


def sigterm_handler(signal, frame):
    global conn, cur
    cur.close()
    conn.close()

    sys.exit(0)


def main():
    signal.signal(signal.SIGTERM, sigterm_handler)

    parser = argparse.ArgumentParser()
    parser.add_argument('--db-connection-url', '-d', help="Database connection URL.", type=str, required=True)

    global conn, cur, args
    args = parser.parse_args()

    conn = psycopg2.connect(args.db_connection_url)
    cur = conn.cursor()

    cur.execute(
        f"SELECT target_framerate FROM envs WHERE running = TRUE")

    res = cur.fetchone()

    if res is None:
        raise RuntimeError('No running env found.')

    target_fps = int(res[0])

    interval = 1 / target_fps
    last_call_time = time.time() - interval

    while True:
        if check_terminate_flag():
            break

        current_time = time.time()
        elapsed_time = current_time - last_call_time

        if elapsed_time >= interval:
            cur.execute("SELECT on_render_frame()")
            conn.commit()

            last_call_time = current_time
        else:
            time.sleep(interval - elapsed_time)

    cur.close()
    conn.close()


if __name__ == '__main__':
    main()
