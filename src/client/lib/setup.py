from setuptools import setup, find_packages

__VERSION__ = '0.0.1'

setup(
    name='pg_game',
    version=__VERSION__,
    author='icitry',
    author_email='icitryofficial@gmail.com',
    description='A simple lib for setting up a client app that communicates with a Postgres Database to run games.',
    packages=find_packages(include=['pg_game']),
    install_requires=['psycopg2'],
    zip_safe=False,
    python_requires=">=3.7",
)
