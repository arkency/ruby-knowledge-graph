CREATE EXTENSION IF NOT EXISTS vector;

CREATE DATABASE planet_development_queue;
CREATE DATABASE planet_test;
CREATE DATABASE planet_test_queue;

\c planet_development_queue
CREATE EXTENSION IF NOT EXISTS vector;

\c planet_test
CREATE EXTENSION IF NOT EXISTS vector;

\c planet_test_queue
CREATE EXTENSION IF NOT EXISTS vector;
