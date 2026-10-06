import ballerina/mcp;

listener mcp:StreamableHttpListener mcpListener = check new (8080);

@mcp:StreamableHttpServiceConfig {
    info: {
        name: "Hotel Reservation MCP Server",
        version: "1.0.0",
        description: "An MCP server that exposes hotel reservation tools for AI agents to search, book, and manage hotel reservations."
    },
    options: {
        instructions: "Use these tools to help users search for available hotel rooms, make reservations, retrieve booking details, and cancel reservations. Always confirm details before making a reservation."
    },
    sessionMode: mcp:STATELESS
}
service mcp:StreamableHttpService /mcp on mcpListener {

    # Check room availability for given dates and guest count.
    #
    # + checkInDate - Check-in date in YYYY-MM-DD format
    # + checkOutDate - Check-out date in YYYY-MM-DD format
    # + numberOfGuests - Number of guests
    # + return - List of available room types with rates and amenities
    remote function checkRoomAvailability(string checkInDate, string checkOutDate, int numberOfGuests) returns AvailabilityResult[]|error {
        int nights = check calculateNights(checkInDate, checkOutDate);
        if nights <= 0 {
            return error("Check-out date must be after check-in date.");
        }
        RoomType[] allRoomTypes = check getRoomTypesFromDb();
        AvailabilityResult[] availableRooms = [];
        foreach RoomType roomType in allRoomTypes {
            if roomType.maxGuests >= numberOfGuests {
                int availableCount = check getAvailableRoomCount(roomType.typeName);
                if availableCount > 0 {
                    availableRooms.push({
                        roomType: roomType.typeName,
                        nightlyRate: roomType.nightlyRate,
                        availableRooms: availableCount,
                        amenities: roomType.amenities
                    });
                }
            }
        }
        return availableRooms;
    }

    # Get all available room types with their nightly rates and amenities.
    #
    # + return - List of all room types offered by the hotel
    remote function getRoomTypes() returns RoomType[]|error {
        return getRoomTypesFromDb();
    }

    # Make a hotel room reservation.
    #
    # + guestName - Full name of the guest
    # + guestEmail - Email address of the guest
    # + roomType - Room type to book (Standard, Deluxe, Suite, Family Room)
    # + checkInDate - Check-in date in YYYY-MM-DD format
    # + checkOutDate - Check-out date in YYYY-MM-DD format
    # + numberOfGuests - Number of guests
    # + return - Reservation details including confirmation ID and total price
    remote function makeReservation(string guestName, string guestEmail, string roomType, string checkInDate, string checkOutDate, int numberOfGuests) returns Reservation|error {
        RoomType|error? foundRoom = getRoomTypeFromDb(roomType);
        if foundRoom is error {
            return foundRoom;
        }
        if foundRoom is () {
            return error(string `Room type '${roomType}' is not available. Valid types: Standard, Deluxe, Suite, Family Room.`);
        }
        if foundRoom.maxGuests < numberOfGuests {
            return error(string `Room type '${roomType}' supports a maximum of ${foundRoom.maxGuests} guests.`);
        }
        int nights = check calculateNights(checkInDate, checkOutDate);
        if nights <= 0 {
            return error("Check-out date must be after check-in date.");
        }
        check decrementAvailability(roomType);
        decimal totalPrice = foundRoom.nightlyRate * <decimal>nights;
        string confirmationId = generateConfirmationId();
        Reservation newReservation = {
            confirmationId: confirmationId,
            guestName: guestName,
            guestEmail: guestEmail,
            roomType: roomType,
            checkInDate: checkInDate,
            checkOutDate: checkOutDate,
            numberOfGuests: numberOfGuests,
            totalPrice: totalPrice,
            status: "CONFIRMED"
        };
        check insertReservation(newReservation);
        return newReservation;
    }

    # Retrieve a hotel reservation by confirmation ID.
    #
    # + confirmationId - The reservation confirmation ID (e.g., HRS-XXXXXXXX)
    # + return - Reservation details
    remote function getReservation(string confirmationId) returns Reservation|error {
        Reservation|error? result = getReservationFromDb(confirmationId);
        if result is error {
            return result;
        }
        if result is () {
            return error(string `No reservation found with confirmation ID: ${confirmationId}`);
        }
        return result;
    }

    # Cancel an existing hotel reservation.
    #
    # + confirmationId - The reservation confirmation ID to cancel
    # + return - Cancellation confirmation message
    remote function cancelReservation(string confirmationId) returns string|error {
        Reservation|error? existing = getReservationFromDb(confirmationId);
        if existing is error {
            return existing;
        }
        if existing is () {
            return error(string `No reservation found with confirmation ID: ${confirmationId}`);
        }
        check deleteReservation(confirmationId);
        check incrementAvailability(existing.roomType);
        return string `Reservation ${confirmationId} for ${existing.guestName} has been successfully cancelled.`;
    }
}
