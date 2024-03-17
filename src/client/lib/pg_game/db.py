import psycopg2
from psycopg2 import Error


class DbConnectionManager:
    def __init__(self, connection_url):
        self._connection = None
        self._cursor = None
        self._connection_url = connection_url

    def create_connection(self):
        try:
            self._connection = psycopg2.connect(self._connection_url)
            self._cursor = self._connection.cursor()
        except Error:
            raise RuntimeError('Error communicating with the server.')

    def terminate_connection(self):
        try:
            self._cursor.close()
            self._connection.close()
        except Error:
            raise RuntimeError('Error communicating with the server.')

    def execute_query(self, query, should_commit=False):
        try:
            self._cursor.execute(query)

            if should_commit:
                self._connection.commit()
        except Error:
            raise RuntimeError('Error executing query.')

    @property
    def cursor(self):
        return self._cursor
