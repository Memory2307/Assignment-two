import ballerina/io;
import ballerina/time;
import ballerina/runtime;
import ballerinax/mysql;
import ballerinax/kafka;

configurable int ticketingPort = 8082;
configurable string kafkaUrl = "localhost:9092";
configurable string dbPassword = "";

// Database client
final mysql:Client ticketingDB = check new ("localhost", "root", dbPassword, "ticketing_system", 3306);

// Kafka consumers and producers
final kafka:Consumer ticketRequestConsumer = check new (kafkaUrl, "ticket.requests", "ticketing-group");
final kafka:Consumer paymentConsumer = check new (kafkaUrl, "payments.processed", "ticketing-group");
final kafka:Producer validationProducer = check new (kafkaUrl, "ticket.validations");

public function main() returns error? {
    io:println("Starting Ticketing Service...");
    
    // Start listening for ticket requests
    _ = start @strand {preferred: true} ticketRequestListener();
    
    // Start listening for payment confirmations
    _ = start @strand {preferred: true} paymentListener();
    
    io:println("Ticketing Service is running. Press Ctrl+C to stop.");
    
    // Keep the service running
    while true {
        runtime:sleep(10);
    }
}

function ticketRequestListener() returns error? {
    while true {
        var result = ticketRequestConsumer->poll(1);
        if result is kafka:ConsumerRecord[] {
            foreach var record in result {
                processTicketRequest(record);
            }
        }
        runtime:sleep(1);
    }
}

function processTicketRequest(kafka:ConsumerRecord record) returns error? {
    json ticketRequest = check record.value.toString().fromJsonString();
    
    string ticketId = ticketRequest.ticketId.toString();
    string passengerId = ticketRequest.passengerId.toString();
    string tripId = ticketRequest.tripId.toString();
    string ticketType = ticketRequest.ticketType.toString();
    decimal price = <decimal>ticketRequest.price;
    
    // Create ticket in database
    _ = check ticketingDB->execute(`
        INSERT INTO tickets (id, passenger_id, trip_id, ticket_type, status, price)
        VALUES (?, ?, ?, ?, 'CREATED', ?)
    `, ticketId, passengerId, tripId, ticketType, price);
    
    io:println("Ticket created: " + ticketId + " for passenger: " + passengerId);
}

function paymentListener() returns error? {
    while true {
        var result = paymentConsumer->poll(1);
        if result is kafka:ConsumerRecord[] {
            foreach var record in result {
                processPaymentConfirmation(record);
            }
        }
        runtime:sleep(1);
    }
}

function processPaymentConfirmation(kafka:ConsumerRecord record) returns error? {
    json payment = check record.value.toString().fromJsonString();
    
    string ticketId = payment.ticketId.toString();
    string status = payment.status.toString();
    
    if status == "COMPLETED" {
        // Update ticket status to PAID
        _ = check ticketingDB->execute(`
            UPDATE tickets SET status = 'PAID' WHERE id = ?
        `, ticketId);
        
        io:println("Ticket paid: " + ticketId);
        
        // Send notification
        json validationEvent = {
            ticketId: ticketId,
            status: "PAID",
            timestamp: time:utcNow()[0].toString()
        };
        
        _ = check validationProducer->send({value: validationEvent.toString()});
    } else {
        // Update ticket status to expired if payment failed
        _ = check ticketingDB->execute(`
            UPDATE tickets SET status = 'EXPIRED' WHERE id = ?
        `, ticketId);
        
        io:println("Ticket expired due to payment failure: " + ticketId);
    }
}