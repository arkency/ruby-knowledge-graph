ALTER USER planet CREATEDB;
CREATE DATABASE planet_production_cache OWNER planet;
CREATE DATABASE planet_production_queue OWNER planet;
\c planet_production
CREATE EXTENSION IF NOT EXISTS vector;
