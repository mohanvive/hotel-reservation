-- Hotel Reservation Service - MySQL Schema & Sample Data
-- Run this script to initialize the hotel_db database

CREATE DATABASE IF NOT EXISTS hotel_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE hotel_db;

-- ============================================================
-- Table: room_types
-- Stores the hotel room categories with pricing and capacity
-- ============================================================
CREATE TABLE IF NOT EXISTS room_types (
    type_name      VARCHAR(50)    NOT NULL,
    nightly_rate   DECIMAL(10,2)  NOT NULL,
    amenities      TEXT           NOT NULL COMMENT 'Comma-separated list of amenities',
    max_guests     INT            NOT NULL,
    PRIMARY KEY (type_name)
);

-- ============================================================
-- Table: room_availability
-- Tracks the number of available rooms per room type
-- ============================================================
CREATE TABLE IF NOT EXISTS room_availability (
    type_name        VARCHAR(50) NOT NULL,
    available_rooms  INT         NOT NULL DEFAULT 0,
    PRIMARY KEY (type_name),
    CONSTRAINT fk_availability_room_type
        FOREIGN KEY (type_name) REFERENCES room_types (type_name)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ============================================================
-- Table: reservations
-- Stores confirmed hotel reservations
-- ============================================================
CREATE TABLE IF NOT EXISTS reservations (
    confirmation_id   VARCHAR(20)    NOT NULL,
    guest_name        VARCHAR(255)   NOT NULL,
    guest_email       VARCHAR(255)   NOT NULL,
    room_type         VARCHAR(50)    NOT NULL,
    check_in_date     VARCHAR(10)    NOT NULL COMMENT 'Format: YYYY-MM-DD',
    check_out_date    VARCHAR(10)    NOT NULL COMMENT 'Format: YYYY-MM-DD',
    number_of_guests  INT            NOT NULL,
    total_price       DECIMAL(10,2)  NOT NULL,
    status            VARCHAR(20)    NOT NULL DEFAULT 'CONFIRMED',
    created_at        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (confirmation_id),
    CONSTRAINT fk_reservation_room_type
        FOREIGN KEY (room_type) REFERENCES room_types (type_name)
        ON UPDATE CASCADE
);

-- ============================================================
-- Sample Data: room_types
-- ============================================================
INSERT INTO room_types (type_name, nightly_rate, amenities, max_guests) VALUES
    ('Standard',    120.00, 'WiFi,TV,Air Conditioning,Private Bathroom',                                              2),
    ('Deluxe',      200.00, 'WiFi,TV,Air Conditioning,Mini-bar,City View,King Bed',                                   2),
    ('Suite',       350.00, 'WiFi,TV,Air Conditioning,Jacuzzi,Living Room,Butler Service,Ocean View',                 3),
    ('Family Room', 280.00, 'WiFi,TV,Air Conditioning,Bunk Beds,Extra Bathroom,Kitchenette',                          5);

-- ============================================================
-- Sample Data: room_availability
-- ============================================================
INSERT INTO room_availability (type_name, available_rooms) VALUES
    ('Standard',    10),
    ('Deluxe',       6),
    ('Suite',        3),
    ('Family Room',  4);

-- ============================================================
-- Sample Data: reservations
-- ============================================================
INSERT INTO reservations (confirmation_id, guest_name, guest_email, room_type, check_in_date, check_out_date, number_of_guests, total_price, status) VALUES
    ('HRS-A1B2C3D4', 'Alice Johnson',  'alice.johnson@example.com',  'Deluxe',      '2026-11-01', '2026-11-05', 2, 800.00,  'CONFIRMED'),
    ('HRS-E5F6G7H8', 'Bob Martinez',   'bob.martinez@example.com',   'Standard',    '2026-11-10', '2026-11-12', 1, 240.00,  'CONFIRMED'),
    ('HRS-I9J0K1L2', 'Carol Williams', 'carol.w@example.com',        'Suite',       '2026-12-24', '2026-12-27', 3, 1050.00, 'CONFIRMED'),
    ('HRS-M3N4O5P6', 'David Chen',     'david.chen@example.com',     'Family Room', '2026-11-20', '2026-11-25', 4, 1400.00, 'CONFIRMED'),
    ('HRS-Q7R8S9T0', 'Emma Davis',     'emma.davis@example.com',     'Standard',    '2026-12-01', '2026-12-03', 2, 240.00,  'CONFIRMED');

-- Adjust availability to reflect the sample reservations above
UPDATE room_availability SET available_rooms = available_rooms - 1 WHERE type_name = 'Deluxe';
UPDATE room_availability SET available_rooms = available_rooms - 2 WHERE type_name = 'Standard';
UPDATE room_availability SET available_rooms = available_rooms - 1 WHERE type_name = 'Suite';
UPDATE room_availability SET available_rooms = available_rooms - 1 WHERE type_name = 'Family Room';
