import argparse
import sys

from . import global_obj
from .env_exec import EnvState
from .postgres_config import PGConfig


def init_config(params: list[str] = None, **kwargs):
    if params is None:
        params = sys.argv[1:]

    parser = argparse.ArgumentParser()
    parser.add_argument('--db-connection-url', '-d', help="Database connection URL.", type=str)
    args = parser.parse_args(params)

    if kwargs.get('db_connection_url') is None and args.db_connection_url is None:
        raise RuntimeError('No Database connection URL provided.')

    db_connection_url = args.db_connection_url if args.db_connection_url is not None \
        else kwargs.get('db_connection_url')

    global_obj.pg_config = PGConfig(db_connection_url=db_connection_url)
    global_obj.env_state = EnvState(global_obj.pg_config._db_connection_url)

    return global_obj.pg_config
