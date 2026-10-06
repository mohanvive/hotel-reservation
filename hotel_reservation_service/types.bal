// Room type with nightly rate and amenities
type RoomType record {|
    string typeName;
    decimal nightlyRate;
    string[] amenities;
    int maxGuests;
|};

// Represents a hotel reservation
type Reservation record {|
    string confirmationId;
    string guestName;
    string guestEmail;
    string roomType;
    string checkInDate;
    string checkOutDate;
    int numberOfGuests;
    decimal totalPrice;
    string status;
|};

// Result of a room availability check
type AvailabilityResult record {|
    string roomType;
    decimal nightlyRate;
    int availableRooms;
    string[] amenities;
|};
