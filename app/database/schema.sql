-- create database
CREATE DATABASE IF NOT EXISTS albumcollector;
USE albumcollector;

-- create tables
CREATE TABLE users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  cognito_sub VARCHAR(64) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  display_name VARCHAR(100) NOT NULL
);

CREATE TABLE user_groups (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  invite_code VARCHAR(10) NOT NULL UNIQUE,
  created_by_user_id BIGINT NOT NULL,

  CONSTRAINT fk_groups_created_by
    FOREIGN KEY (created_by_user_id)
    REFERENCES users(id)
);

CREATE TABLE group_members (
  group_id BIGINT NOT NULL,
  user_id BIGINT NOT NULL,
  role ENUM('owner', 'member') NOT NULL DEFAULT 'member',

  PRIMARY KEY (group_id, user_id),

  CONSTRAINT fk_group_members_group
    FOREIGN KEY (group_id)
    REFERENCES user_groups(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_group_members_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
);

CREATE TABLE stickers (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  country VARCHAR(100)
);

CREATE TABLE collection (
  user_id BIGINT NOT NULL,
  sticker_id BIGINT NOT NULL,
  amount INT NOT NULL DEFAULT 0,
  needs BOOL NOT NULL DEFAULT 0,
  
  PRIMARY KEY (user_id, sticker_id),

  FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,

  FOREIGN KEY (sticker_id)
    REFERENCES stickers(id)
    ON DELETE CASCADE,

  CHECK (amount >= 0)
);

CREATE TABLE trade_calculations (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  group_id BIGINT NOT NULL,
  status ENUM('processing', 'completed', 'failed') NOT NULL DEFAULT 'completed',
  started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  error_message TEXT NULL,

  FOREIGN KEY (group_id)
    REFERENCES user_groups(id)
    ON DELETE CASCADE
);

CREATE TABLE trades (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  group_id BIGINT NOT NULL,
  status ENUM('available', 'stale') NOT NULL DEFAULT 'available',

  FOREIGN KEY (group_id)
    REFERENCES user_groups(id)
    ON DELETE CASCADE
);

CREATE TABLE trade_steps (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  trade_id BIGINT NOT NULL,
  step_order INT NOT NULL,
  from_user_id BIGINT NOT NULL,
  to_user_id BIGINT NOT NULL,
  sticker_id BIGINT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,

  FOREIGN KEY (trade_id)
    REFERENCES trades(id)
    ON DELETE CASCADE,

  FOREIGN KEY (from_user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,

  FOREIGN KEY (to_user_id)
    REFERENCES users(id)
    ON DELETE CASCADE,

  FOREIGN KEY (sticker_id)
    REFERENCES stickers(id)
    ON DELETE CASCADE,

  UNIQUE KEY uq_trade_step_order
    (trade_id, step_order)
);