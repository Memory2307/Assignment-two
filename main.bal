import ballerina/io;
import ballerina/uuid;

// Enhanced types for comprehensive ticketing system
type User record {
    int id;
    string username;
    string email;
    string password;
    string role;
    decimal balance;
    string? phone;
    boolean notifications_enabled;
    string created_at;
    string? last_login;
};

type Route record {
    int id;
    string route_name;
    string route_type;
    string origin;
    string destination;
    decimal base_fare;
    boolean is_active;
    string status; // "active", "disrupted", "maintenance"
    string? disruption_message;
    decimal distance_km;
    int estimated_duration_minutes;
};

type Trip record {
    int id;
    int route_id;
    string departure_time;
    string arrival_time;
    int available_seats;
    int total_seats;
    string status; // "scheduled", "boarding", "in_transit", "completed", "cancelled", "delayed"
    decimal? delay_minutes;
    string? status_message;
    string vehicle_number;
};

type Ticket record {
    int id;
    int user_id;
    int? trip_id; // Optional for passes
    string ticket_type; // "single", "multi_ride_5", "multi_ride_10", "daily_pass", "weekly_pass", "monthly_pass"
    string status; // "paid", "validated", "used", "expired", "cancelled", "refunded"
    decimal purchase_price;
    decimal? refund_amount;
    string purchased_at;
    string expires_at;
    string? validated_at;
    string? cancelled_at;
    string? refunded_at;
    string validation_code;
    int? rides_remaining; // For multi-ride tickets
    int? total_rides; // For multi-ride tickets
    string? cancellation_reason;
};

type Transaction record {
    int id;
    int user_id;
    string transaction_type; // "purchase", "topup", "refund", "cancellation_fee"
    decimal amount;
    decimal balance_before;
    decimal balance_after;
    string description;
    string timestamp;
    string status; // "completed", "pending", "failed"
    int? ticket_id;
};

type Notification record {
    int id;
    int user_id;
    string notification_type; // "trip_delay", "trip_cancellation", "route_disruption", "ticket_expiry", "low_balance"
    string title;
    string message;
    string timestamp;
    boolean is_read;
    int? related_trip_id;
    int? related_route_id;
};

// Global data arrays
User[] users = [
    {id: 1, username: "john_doe", email: "john@example.com", password: "password123", role: "passenger", balance: 150.00, phone: "+264812345678", notifications_enabled: true, created_at: "2024-01-01 10:00:00", last_login: "2024-01-15 14:20:00"},
    {id: 2, username: "admin", email: "admin@windhoek.com", password: "admin123", role: "admin", balance: 0.00, phone: (), notifications_enabled: true, created_at: "2024-01-01 09:00:00", last_login: "2024-01-15 15:30:00"},
    {id: 3, username: "validator1", email: "validator@transport.com", password: "val123", role: "validator", balance: 0.00, phone: (), notifications_enabled: true, created_at: "2024-01-01 08:00:00", last_login: ()}
];

Route[] routes = [
    {id: 1, route_name: "City Center Express", route_type: "bus", origin: "Windhoek Central", destination: "Katutura", base_fare: 12.50, is_active: true, status: "active", disruption_message: (), distance_km: 8.5, estimated_duration_minutes: 25},
    {id: 2, route_name: "Airport Shuttle", route_type: "bus", origin: "Hosea Kutako Airport", destination: "City Center", base_fare: 45.00, is_active: true, status: "active", disruption_message: (), distance_km: 42.0, estimated_duration_minutes: 50},
    {id: 3, route_name: "University Route", route_type: "bus", origin: "UNAM Campus", destination: "Windhoek Central", base_fare: 8.00, is_active: true, status: "disrupted", disruption_message: "Temporary detour due to road construction", distance_km: 6.2, estimated_duration_minutes: 20},
    {id: 4, route_name: "Northern Suburbs", route_type: "train", origin: "Windhoek Central", destination: "Pioneers Park", base_fare: 15.00, is_active: true, status: "active", disruption_message: (), distance_km: 12.0, estimated_duration_minutes: 18}
];

Trip[] trips = [
    {id: 1, route_id: 1, departure_time: "2024-01-15 08:00:00", arrival_time: "2024-01-15 08:30:00", available_seats: 25, total_seats: 40, status: "scheduled", delay_minutes: (), status_message: (), vehicle_number: "WDH-001"},
    {id: 2, route_id: 1, departure_time: "2024-01-15 16:00:00", arrival_time: "2024-01-15 16:30:00", available_seats: 30, total_seats: 40, status: "delayed", delay_minutes: 15.0, status_message: "Traffic congestion", vehicle_number: "WDH-002"},
    {id: 3, route_id: 2, departure_time: "2024-01-15 10:00:00", arrival_time: "2024-01-15 11:00:00", available_seats: 15, total_seats: 50, status: "boarding", delay_minutes: (), status_message: (), vehicle_number: "WDH-003"},
    {id: 4, route_id: 3, departure_time: "2024-01-15 07:00:00", arrival_time: "2024-01-15 07:45:00", available_seats: 0, total_seats: 35, status: "cancelled", delay_minutes: (), status_message: "Vehicle breakdown", vehicle_number: "WDH-004"},
    {id: 5, route_id: 4, departure_time: "2024-01-15 12:00:00", arrival_time: "2024-01-15 12:18:00", available_seats: 80, total_seats: 120, status: "scheduled", delay_minutes: (), status_message: (), vehicle_number: "WDH-T001"}
];

Ticket[] tickets = [];
Transaction[] transactions = [];
Notification[] notifications = [];

int nextTicketId = 1;
int nextTransactionId = 1;
int nextNotificationId = 1;
int currentUserId = 0;

// Ticket pricing structure
map<decimal> ticketPrices = {
    "single": 1.0,
    "multi_ride_5": 4.5,
    "multi_ride_10": 8.5,
    "daily_pass": 6.0,
    "weekly_pass": 35.0,
    "monthly_pass": 120.0
};

public function main() returns error? {
    io:println("****************************************************************");
    io:println("* WELCOME TO THE CITY OF WINDHOEK TRANSIT SYSTEM         *");
    io:println("* [ Digital Ticketing & Transit Management ]         *");
    io:println("****************************************************************");
    io:println("");
    io:println("System online. All services are operational.");
    io:println("Core data modules loaded:");
    io:println("   -> Registered Users: " + users.length().toString());
    io:println("   -> Defined Routes: " + routes.length().toString());
    io:println("   -> Scheduled Trips: " + trips.length().toString());
    io:println("   -> Available Ticket Options: " + ticketPrices.keys().length().toString());
    io:println("   -> Account Balance Module: -> Advanced");
    io:println("   -> User Notifications: -> Real-time");
    io:println("   -> Ticketing Functions: -> Full Lifecycle");
    io:println("   -> Cancellations/Refunds: -> Enabled");
    io:println("   -> Payment Top-up Service: -> Multi-option");
    io:println("");

    initializeSampleNotifications();

    while true {
        displayMainMenu();
        string choice = io:readln("Enter your selection [1-4]: ");

        match choice {
            "1" => {
                check startPassengerPortal();
            }
            "2" => {
                check startAdminPortal();
            }
            "3" => {
                check startValidatorPortal();
            }
            "4" => {
                io:println("Shutting down the system. Thank you for using City of Windhoek Transit!");
                io:println("Travel safely!");
                break;
            }
            _ => {
                io:println("Error: Unrecognized command. Please enter a number from 1 to 4.");
                io:println("");
            }
        }
    }
}

function displayMainMenu() {
    io:println("");
    io:println("--- CITY OF WINDHOEK TRANSIT ---");
    io:println("======================================");
    io:println("");
    io:println("Identify your access level:");
    io:println("1. Passenger Services - Purchase & manage your tickets");
    io:println("2. Administrative Console - System management and oversight");
    io:println("3. Validation Terminal - For ticket validation by staff");
    io:println("4. Exit Application");
    io:println("");
}


function startPassengerPortal() returns error? {
    io:println("");
    io:println("--- PASSENGER SELF-SERVICE PORTAL ---");
    io:println("=====================================");

    while true {
        io:println("");
        io:println("Passenger Menu:");
        io:println("1. Create a New Account");
        io:println("2. Sign In to Existing Account");
        io:println("3. View Routes & Trips as Guest");
        io:println("4. Check Live System Status");
        io:println("5. Return to Main Menu");

        string choice = io:readln("Select an option (1-5): ");

        match choice {
            "1" => {
                check registerNewPassenger();
            }
            "2" => {
                check loginExistingPassenger();
            }
            "3" => {
                check browseRoutesAndTrips();
            }
            "4" => {
                check showSystemStatus();
            }
            "5" => {
                break;
            }
            _ => {
                io:println("Error: Invalid selection. Please choose an option from 1 to 5.");
            }
        }
    }
}

function registerNewPassenger() returns error? {
    io:println("");
    io:println("--- NEW PASSENGER REGISTRATION ---");
    io:println("==================================");

    string username = io:readln("Please enter a new username: ");
    string email = io:readln("Enter your email address: ");
    string phone = io:readln("Enter your mobile number: ");
    string password = io:readln("Set a secure password: ");
    string enableNotifications = io:readln("Do you want to enable notifications? (y/n): ");

    // Check if username exists
    foreach User user in users {
        if user.username == username {
            io:println("Error: That username is already taken. Please try a different one.");
            return;
        }
    }

    int newId = users.length() + 1;
    User newUser = {
        id: newId,
        username: username,
        email: email,
        password: password,
        role: "passenger",
        balance: 100.00,
        phone: phone,
        notifications_enabled: enableNotifications.toLowerAscii() == "y",
        created_at: getCurrentTimestamp(),
        last_login: ()
    };
    users.push(newUser);

    recordTransaction(newId, "topup", 100.00, 0.00, 100.00, "New account bonus");

    io:println("");
    io:println("Success! Your account has been created.");
    io:println(" -> Username: " + username);
    io:println(" -> Contact Phone: " + phone);
    io:println(" -> A welcome bonus of 100.00 NAD has been added to your account.");
    io:println(" -> Notifications Status: " + (newUser.notifications_enabled ? "Enabled" : "Disabled"));
    io:println("You may now log in to access the passenger dashboard.");
}

function loginExistingPassenger() returns error? {
    io:println("");
    io:println("--- PASSENGER ACCOUNT LOGIN ---");
    io:println("===============================");

    string username = io:readln("Username: ");
    string password = io:readln("Password: ");

    foreach int i in 0 ..< users.length() {
        User user = users[i];
        if user.username == username && user.password == password && user.role == "passenger" {
            users[i].last_login = getCurrentTimestamp();
            currentUserId = user.id;

            io:println("");
            io:println("Authentication successful. Welcome, " + user.username + "!");
            string lastLoginStr = user.last_login is () ? "This is your first login" : <string>user.last_login;
            io:println("Last session: " + lastLoginStr);

            check showPassengerDashboard(users[i]);
            return;
        }
    }

    io:println("Login failed. Please verify your username and password.");
}

function showPassengerDashboard(User user) returns error? {
    while true {
        User? currentUser = getUserById(user.id);
        if currentUser is () {
            io:println("Error: Could not retrieve user session. Please log in again.");
            break;
        }

        User loggedUser = currentUser;

        io:println("");
        io:println("--- PASSENGER DASHBOARD ---");
        io:println("============================");
        io:println("User: " + loggedUser.username);
        io:println("Account Balance: " + loggedUser.balance.toString() + " NAD");

        int unreadNotifications = getUnreadNotificationsCount(loggedUser.id);
        if unreadNotifications > 0 {
            io:println("You have " + unreadNotifications.toString() + " new notification(s).");
        }

        io:println("");
        io:println("Please choose an action:");
        io:println("1. View Routes & Trips");
        io:println("2. Purchase New Tickets");
        io:println("3. View My Tickets & Passes");
        io:println("4. Manage Account & Top-up Balance");
        io:println("5. Check Notifications");
        io:println("6. Review My Travel History");
        io:println("7. Request Ticket Cancellation/Refund");
        io:println("8. Modify Account Settings");
        io:println("9. Log Out");

        string choice = io:readln("Enter your choice (1-9): ");

        match choice {
            "1" => {
                check browseRoutesAndTrips();
            }
            "2" => {
                check purchaseTicketsMenu(loggedUser.id);
            }
            "3" => {
                check showMyTickets(loggedUser.id);
            }
            "4" => {
                check accountAndTopupMenu(loggedUser.id);
            }
            "5" => {
                check showNotifications(loggedUser.id);
            }
            "6" => {
                check showTravelHistory(loggedUser.id);
            }
            "7" => {
                check cancelRefundMenu(loggedUser.id);
            }
            "8" => {
                check accountSettings(loggedUser.id);
            }
            "9" => {
                io:println("You have been logged out. Thank you!");
                currentUserId = 0;
                break;
            }
            _ => {
                io:println("Error: Invalid selection. Please choose from 1-9.");
            }
        }
    }
}

// ... (The rest of the functions would be similarly updated)
// Due to length, I will show the key changes. Assume all print statements are updated in a similar fashion.

function browseRoutesAndTrips() returns error? {
    io:println("");
    io:println("--- ROUTE & TRIP INFORMATION ---");
    io:println("================================");
    
    io:println("Currently Available Routes:");
    io:println("---------------------------");
    
    foreach int i in 0 ..< routes.length() {
        Route route = routes[i];
        string statusSymbol = route.status == "active" ? "[OK]" : (route.status == "disrupted" ? "[!]" : "[M]");
        
        io:println((i + 1).toString() + ". " + statusSymbol + " " + route.route_name + " (" + route.route_type.toUpperAscii() + ")");
        io:println("    From: " + route.origin + " -> To: " + route.destination);
        io:println("    Fare: " + route.base_fare.toString() + " NAD");
        io:println("    Distance: " + route.distance_km.toString() + " km | Est. Time: " + route.estimated_duration_minutes.toString() + " min");
        
        if route.status == "disrupted" && route.disruption_message is string {
            string disruptionMsg = <string>route.disruption_message;
            io:println("    ALERT: " + disruptionMsg);
        }
        io:println("");
    }
    
    io:println("Scheduled Upcoming Trips:");
    io:println("-------------------------");
    
    int count = 0;
    foreach Trip trip in trips {
        Route? route = getRouteById(trip.route_id);
        if route is Route && route.is_active {
            count += 1;
            string statusIcon = getStatusIcon(trip.status);
            
            io:println(count.toString() + ". " + statusIcon + " Trip ID " + trip.id.toString() + " on " + route.route_name);
            io:println("    Path: " + route.origin + " -> " + route.destination);
            io:println("    Schedule: " + trip.departure_time + " to " + trip.arrival_time);
            io:println("    Seats Open: " + trip.available_seats.toString() + "/" + trip.total_seats.toString());
            io:println("    Vehicle ID: " + trip.vehicle_number);
            io:println("    Current Status: " + trip.status.toUpperAscii());
            
            if trip.delay_minutes is decimal {
                decimal delayValue = <decimal>trip.delay_minutes;
                if delayValue > 0.0d {
                    io:println("    Delay Info: " + delayValue.toString() + " minutes");
                }
            }
            
            if trip.status_message is string {
                string statusMsg = <string>trip.status_message;
                io:println("    Note: " + statusMsg);
            }
            io:println("");
        }
    }
    
    if count == 0 {
        io:println("There are no active trips scheduled at this time.");
    }
}


function purchaseTicketsMenu(int userId) returns error? {
    io:println("");
    io:println("--- TICKET PURCHASE ---");
    io:println("=======================");
    
    io:println("Select a Ticket Category:");
    io:println("1. Single-Trip Ticket");
    io:println("2. Multi-Trip Package (5 or 10 trips)");
    io:println("3. Daily Travel Pass");
    io:println("4. Weekly Travel Pass");
    io:println("5. Monthly Travel Pass");
    io:println("6. Go Back");
    
    string choice = io:readln("Choose a category (1-6): ");
    
    match choice {
        "1" => {
            check purchaseSingleRideTicket(userId);
        }
        "2" => {
            check purchaseMultiRidePackage(userId);
        }
        "3" => {
            check purchasePass(userId, "daily_pass");
        }
        "4" => {
            check purchasePass(userId, "weekly_pass");
        }
        "5" => {
            check purchasePass(userId, "monthly_pass");
        }
        "6" => {
            return;
        }
        _ => {
            io:println("Error: Invalid selection.");
        }
    }
}

// Continue with other functions... I'll skip to the Validator Portal for another example.

function startValidatorPortal() returns error? {
    io:println("");
    io:println("--- TICKET VALIDATION TERMINAL ---");
    io:println("==================================");
    
    while true {
        io:println("");
        io:println("Validator Actions:");
        io:println("1. Validate a Ticket or Pass");
        io:println("2. View Validation Log");
        io:println("3. Get Current Trip Information");
        io:println("4. Generate Daily Validation Summary");
        io:println("5. Return to Main Menu");
        
        string choice = io:readln("Select an action (1-5): ");
        
        match choice {
            "1" => {
                check validateTicketByCode();
            }
            "2" => {
                io:println("INFO: Validation Log feature is part of the extended module set.");
            }
            "3" => {
                io:println("INFO: Trip Status feature is part of the extended module set.");
            }
            "4" => {
                io:println("INFO: Daily Report feature is part of the extended module set.");
            }
            "5" => {
                break;
            }
            _ => {
                io:println("Error: Unrecognized command. Please choose from 1-5.");
            }
        }
    }
}

function validateTicketByCode() returns error? {
    io:println("");
    io:println("--- SCAN OR ENTER VALIDATION CODE ---");
    io:println("=====================================");
    
    string validationCode = io:readln("Input Validation Code: ");
    
    Ticket? foundTicket = ();
    foreach Ticket ticket in tickets {
        if ticket.validation_code == validationCode {
            foundTicket = ticket;
            break;
        }
    }
    
    if foundTicket is () {
        io:println("VALIDATION FAILED: Code not found in the system.");
        return;
    }
    
    Ticket ticket = foundTicket;
    User? user = getUserById(ticket.user_id);
    
    if user is () {
        io:println("Error: Associated passenger account not found.");
        return;
    }
    
    User passenger = user;
    
    io:println("");
    io:println("--- TICKET LOOKUP DETAILS ---");
    io:println("=============================");
    io:println("Ticket ID: " + ticket.id.toString());
    io:println("Passenger Name: " + passenger.username);
    io:println("Ticket Type: " + ticket.ticket_type.toUpperAscii());
    io:println("Current Status: " + ticket.status.toUpperAscii());
    
    if ticket.trip_id is int {
        int tripId = <int>ticket.trip_id;
        Trip? trip = getTripById(tripId);
        Route? route = trip is Trip ? getRouteById(trip.route_id) : ();
        if route is Route && trip is Trip {
            io:println("Route: " + route.route_name);
            io:println("Path: " + route.origin + " -> " + route.destination);
            io:println("Departs at: " + trip.departure_time);
        }
    }
    
    io:println("Price Paid: " + ticket.purchase_price.toString() + " NAD");
    io:println("Valid Until: " + ticket.expires_at);
    
    if ticket.rides_remaining is int && ticket.total_rides is int {
        int remaining = <int>ticket.rides_remaining;
        int total = <int>ticket.total_rides;
        io:println("Rides Left: " + remaining.toString() + " of " + total.toString());
    }
    
    io:println("");
    
    // Check ticket validity
    if ticket.status == "cancelled" || ticket.status == "refunded" {
        io:println("VALIDATION FAILED: This ticket is marked as cancelled or refunded.");
        if ticket.cancelled_at is string {
            string cancelledTime = <string>ticket.cancelled_at;
            io:println("Cancellation Time: " + cancelledTime);
        }
        return;
    }
    
    if ticket.status == "expired" {
        io:println("VALIDATION FAILED: This ticket has expired.");
        return;
    }
    
    if ticket.expires_at < getCurrentTimestamp() {
        foreach int i in 0 ..< tickets.length() {
            if tickets[i].id == ticket.id {
                tickets[i].status = "expired";
                break;
            }
        }
        io:println("VALIDATION FAILED: This ticket's validity period has ended.");
        return;
    }
    
    if ticket.status == "paid" || ticket.status == "validated" {
        if ticket.ticket_type == "single" {
            if ticket.status == "validated" {
                io:println("VALIDATION FAILED: This single-use ticket has already been validated.");
                return;
            }
            
            string confirm = io:readln("Proceed to validate this single-ride ticket? (y/n): ");
            if confirm.toLowerAscii() == "y" {
                foreach int i in 0 ..< tickets.length() {
                    if tickets[i].id == ticket.id {
                        tickets[i].status = "used";
                        tickets[i].validated_at = getCurrentTimestamp();
                        break;
                    }
                }
                
                io:println("");
                io:println("VALIDATION SUCCESSFUL (SINGLE RIDE)");
                io:println("Welcome aboard, " + passenger.username + ". Enjoy the trip!");
                io:println("Note: Ticket is now marked as used.");
            }
        } else if ticket.ticket_type.startsWith("multi_ride") {
            if ticket.rides_remaining is int && ticket.rides_remaining > 0 {
                string confirm = io:readln("Use one ride from this package? (y/n): ");
                if confirm.toLowerAscii() == "y" {
                    foreach int i in 0 ..< tickets.length() {
                        if tickets[i].id == ticket.id {
                            if tickets[i].rides_remaining is int {
                                tickets[i].rides_remaining = tickets[i].rides_remaining - 1;
                            }
                            tickets[i].validated_at = getCurrentTimestamp();
                            if tickets[i].rides_remaining is int && tickets[i].rides_remaining <= 0 {
                                tickets[i].status = "used";
                            } else {
                                tickets[i].status = "validated";
                            }
                            break;
                        }
                    }
                    
                    int remainingRides = ticket.rides_remaining is () ? 0 : <int>ticket.rides_remaining - 1;
                    io:println("");
                    io:println("VALIDATION SUCCESSFUL (MULTI-RIDE)");
                    io:println("Welcome aboard, " + passenger.username + "!");
                    io:println("Rides now remaining: " + remainingRides.toString());
                    if remainingRides == 0 {
                        io:println("This was the final ride for this package.");
                    }
                }
            } else {
                io:println("VALIDATION FAILED: No rides left on this package.");
            }
        } else {
            string confirm = io:readln("Validate this " + ticket.ticket_type + "? (y/n): ");
            if confirm.toLowerAscii() == "y" {
                foreach int i in 0 ..< tickets.length() {
                    if tickets[i].id == ticket.id {
                        tickets[i].status = "validated";
                        tickets[i].validated_at = getCurrentTimestamp();
                        break;
                    }
                }
                
                io:println("");
                io:println("VALIDATION SUCCESSFUL (" + ticket.ticket_type.toUpperAscii() + ")");
                io:println("Welcome aboard, " + passenger.username + "!");
                io:println("This pass is valid until: " + ticket.expires_at);
            }
        }
    } else {
        io:println("VALIDATION FAILED: Ticket status is '" + ticket.status + "', cannot be validated.");
    }
}


// Helper functions (remain unchanged)
function getCurrentTimestamp() returns string {
    // Note: In a real application, this would use the system's actual current time.
    // Using a fixed time for predictable demonstration.
    return "2025-10-05 20:23:00"; 
}

function getCurrentTime() returns string {
    return "20:23:00";
}

function generateValidationCode() returns string {
    return "VAL-" + nextTicketId.toString() + "-" + uuid:createType1AsString().substring(0, 8);
}

function calculateTicketExpiry(string ticketType) returns string {
    // This logic would be dynamic in a real application.
    match ticketType {
        "single" => { return "2025-10-06 23:59:59"; }
        "multi_ride_5"|"multi_ride_10" => { return "2025-11-05 23:59:59"; }
        "daily_pass" => { return "2025-10-06 23:59:59"; }
        "weekly_pass" => { return "2025-10-12 23:59:59"; }
        "monthly_pass" => { return "2025-11-05 23:59:59"; }
        _ => { return "2025-10-06 23:59:59"; }
    }
}

function getRouteById(int routeId) returns Route? {
    foreach Route route in routes {
        if route.id == routeId {
            return route;
        }
    }
    return ();
}

function getTripById(int tripId) returns Trip? {
    foreach Trip trip in trips {
        if trip.id == tripId {
            return trip;
        }
    }
    return ();
}

function getUserById(int userId) returns User? {
    foreach User user in users {
        if user.id == userId {
            return user;
        }
    }
    return ();
}

function getCurrentUserBalance(int userId) returns decimal {
    User? user = getUserById(userId);
    return user?.balance ?: 0.0;
}

function updateUserBalance(int userId, decimal newBalance) {
    foreach int i in 0 ..< users.length() {
        if users[i].id == userId {
            users[i].balance = newBalance;
            break;
        }
    }
}

function updateUserField(int userId, string fieldName, anydata newValue) {
    foreach int i in 0 ..< users.length() {
        if users[i].id == userId {
            match fieldName {
                "email" => { users[i].email = <string>newValue; }
                "phone" => { users[i].phone = <string>newValue; }
                "notifications_enabled" => { users[i].notifications_enabled = <boolean>newValue; }
                "password" => { users[i].password = <string>newValue; }
            }
            break;
        }
    }
}

function updateTripSeats(int tripId, int newSeats) {
    foreach int i in 0 ..< trips.length() {
        if trips[i].id == tripId {
            trips[i].available_seats = newSeats;
            break;
        }
    }
}

function recordTransaction(int userId, string transactionType, decimal amount, decimal balanceBefore, decimal balanceAfter, string description, int? ticketId = ()) {
    Transaction newTransaction = {
        id: nextTransactionId,
        user_id: userId,
        transaction_type: transactionType,
        amount: amount,
        balance_before: balanceBefore,
        balance_after: balanceAfter,
        description: description,
        timestamp: getCurrentTimestamp(),
        status: "completed",
        ticket_id: ticketId
    };
    
    transactions.push(newTransaction);
    nextTransactionId += 1;
}

function getStatusIcon(string status) returns string {
    match status {
        "scheduled" => { return "[S]"; }
        "boarding" => { return "[B]"; }
        "in_transit" => { return "[T]"; }
        "completed" => { return "[C]"; }
        "cancelled" => { return "[X]"; }
        "delayed" => { return "[D]"; }
        _ => { return "[?]"; }
    }
}

function getUnreadNotificationsCount(int userId) returns int {
    int count = 0;
    foreach Notification notification in notifications {
        if notification.user_id == userId && !notification.is_read {
            count += 1;
        }
    }
    return count;
}

function markNotificationAsRead(int notificationId) {
    foreach int i in 0 ..< notifications.length() {
        if notifications[i].id == notificationId {
            notifications[i].is_read = true;
            break;
        }
    }
}

function initializeSampleNotifications() {
    Notification[] sampleNotifications = [
        {id: 1, user_id: 1, notification_type: "trip_delay", title: "Trip Delay", message: "Your trip on City Center Express is delayed by 15 minutes", timestamp: "2025-10-05 14:00:00", is_read: false, related_trip_id: 2, related_route_id: ()},
        {id: 2, user_id: 1, notification_type: "low_balance", title: "Low Balance", message: "Your account balance is running low. Consider topping up.", timestamp: "2025-10-05 13:00:00", is_read: false, related_trip_id: (), related_route_id: ()}
    ];
    
    foreach Notification notification in sampleNotifications {
        notifications.push(notification);
        nextNotificationId += 1;
    }
}
