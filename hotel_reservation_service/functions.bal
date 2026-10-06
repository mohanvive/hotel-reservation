import ballerina/sql;
import ballerina/time;
import ballerina/uuid;

// DB row type for room_types table
type RoomTypeRow record {|
    string type_name;
    decimal nightly_rate;
    string amenities;
    int max_guests;
|};

// DB row type for room_availability table
type RoomAvailabilityRow record {|
    string type_name;
    int available_rooms;
|};

// DB row type for reservations table
type ReservationRow record {|
    string confirmation_id;
    string guest_name;
    string guest_email;
    string room_type;
    string check_in_date;
    string check_out_date;
    int number_of_guests;
    decimal total_price;
    string status;
|};

// Fetch all room types from the database
function getRoomTypesFromDb() returns RoomType[]|error {
    stream<RoomTypeRow, sql:Error?> resultStream = dbClient->query(`SELECT type_name, nightly_rate, amenities, max_guests FROM room_types`);
    RoomType[] roomTypes = [];
    check from RoomTypeRow row in resultStream
        do {
            string[] amenitiesList = re`,`.split(row.amenities);
            roomTypes.push({
                typeName: row.type_name,
                nightlyRate: row.nightly_rate,
                amenities: amenitiesList,
                maxGuests: row.max_guests
            });
        };
    return roomTypes;
}

// Fetch available rooms for a given room type from the database
function getAvailableRoomCount(string roomTypeName) returns int|error {
    int count = check dbClient->queryRow(`SELECT available_rooms FROM room_availability WHERE type_name = ${roomTypeName}`);
    return count;
}

// Fetch a single room type from the database
function getRoomTypeFromDb(string typeName) returns RoomType|error? {
    RoomTypeRow|sql:Error result = dbClient->queryRow(`SELECT type_name, nightly_rate, amenities, max_guests FROM room_types WHERE type_name = ${typeName}`);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    string[] amenitiesList = re`,`.split(result.amenities);
    return {
        typeName: result.type_name,
        nightlyRate: result.nightly_rate,
        amenities: amenitiesList,
        maxGuests: result.max_guests
    };
}

// Decrement available room count after a booking
function decrementAvailability(string roomTypeName) returns error? {
    sql:ExecutionResult result = check dbClient->execute(`UPDATE room_availability SET available_rooms = available_rooms - 1 WHERE type_name = ${roomTypeName} AND available_rooms > 0`);
    int? affectedRows = result.affectedRowCount;
    if affectedRows is () || affectedRows == 0 {
        return error(string `No rooms of type '${roomTypeName}' are currently available.`);
    }
}

// Increment available room count after a cancellation
function incrementAvailability(string roomTypeName) returns error? {
    _ = check dbClient->execute(`UPDATE room_availability SET available_rooms = available_rooms + 1 WHERE type_name = ${roomTypeName}`);
}

// Insert a new reservation into the database
function insertReservation(Reservation reservation) returns error? {
    _ = check dbClient->execute(`
        INSERT INTO reservations (confirmation_id, guest_name, guest_email, room_type, check_in_date, check_out_date, number_of_guests, total_price, status)
        VALUES (${reservation.confirmationId}, ${reservation.guestName}, ${reservation.guestEmail}, ${reservation.roomType}, ${reservation.checkInDate}, ${reservation.checkOutDate}, ${reservation.numberOfGuests}, ${reservation.totalPrice}, ${reservation.status})
    `);
}

// Fetch a reservation by confirmation ID from the database
function getReservationFromDb(string confirmationId) returns Reservation|error? {
    ReservationRow|sql:Error result = dbClient->queryRow(`SELECT confirmation_id, guest_name, guest_email, room_type, check_in_date, check_out_date, number_of_guests, total_price, status FROM reservations WHERE confirmation_id = ${confirmationId}`);
    if result is sql:NoRowsError {
        return ();
    }
    if result is sql:Error {
        return result;
    }
    return {
        confirmationId: result.confirmation_id,
        guestName: result.guest_name,
        guestEmail: result.guest_email,
        roomType: result.room_type,
        checkInDate: result.check_in_date,
        checkOutDate: result.check_out_date,
        numberOfGuests: result.number_of_guests,
        totalPrice: result.total_price,
        status: result.status
    };
}

// Delete a reservation from the database
function deleteReservation(string confirmationId) returns error? {
    sql:ExecutionResult result = check dbClient->execute(`DELETE FROM reservations WHERE confirmation_id = ${confirmationId}`);
    int? affectedRows = result.affectedRowCount;
    if affectedRows is () || affectedRows == 0 {
        return error(string `No reservation found with confirmation ID: ${confirmationId}`);
    }
}

// Calculate number of nights between two date strings (YYYY-MM-DD)
function calculateNights(string checkInDate, string checkOutDate) returns int|error {
    time:Civil checkIn = check time:civilFromString(checkInDate + "T00:00:00Z");
    time:Civil checkOut = check time:civilFromString(checkOutDate + "T00:00:00Z");
    time:Utc checkInUtc = check time:utcFromCivil(checkIn);
    time:Utc checkOutUtc = check time:utcFromCivil(checkOut);
    decimal diffSeconds = <decimal>(checkOutUtc[0] - checkInUtc[0]);
    int nights = <int>(diffSeconds / 86400d);
    return nights;
}

// Generate a unique confirmation ID using UUID
function generateConfirmationId() returns string {
    string uuidStr = uuid:createType4AsString();
    string shortId = uuidStr.substring(0, 8).toUpperAscii();
    return "HRS-" + shortId;
}
