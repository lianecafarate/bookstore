import ballerina/test;
import ballerina/http;

//bal test --code-coverage --test-report
string bookstoreUrl = "http://localhost:8080";

http:Client bookstoreClient = check new(bookstoreUrl);
function beforeFunc1() {
    // Clear the table and reset to initial state
    books.removeAll();
    books.add({ id: "1", title: "1984", author: "George Orwell", year: 1949 });
    books.add({ id: "2", title: "To Kill a Mockingbird", author: "Harper Lee", year: 1960 });
    books.add({ id: "3", title: "The Great Gatsby", author: "F. Scott Fitzgerald", year: 1925 });
}

@test:Config {
    before: beforeFunc1
}

function addNewBookSuccessTest() returns error? {
    Book newBook = {
        id: "4",
        title: "The Handmaid's Tale",
        author: "Margaret Atwood",
        year: 1985
    };

    http:Response response = check bookstoreClient->post("/books", newBook);
    // Check for 201 Created
    test:assertEquals(actual = response.statusCode, expected = http:STATUS_CREATED);
    // Check that the response body contains the newly created book
    test:assertEquals(actual = check response.getJsonPayload(), expected = newBook);
}

@test:Config {
    before: beforeFunc1
}
function addNewBookConflictTest() returns error? {
    Book existingBook = {
        id: "1",
        title: "1984",
        author: "George Orwell",
        year: 1949
    };

    http:Response response = check bookstoreClient->post("/books", existingBook);

    // Check for 409 Conflict
    test:assertEquals(actual = response.statusCode, expected = http:STATUS_CONFLICT);

    // Check for the correct JSON error structure
    json expectedError = { message: "Book with ID " + existingBook.id + " already exists."};
    // Check that the response body contains the expected error
    test:assertEquals(actual = check response.getJsonPayload(), expected = expectedError);
}

@test:Config {
    dependsOn: [addNewBookSuccessTest]
}
function getAllBooksTest() returns error? {
    http:Response response = check bookstoreClient->get("/books");
    // Check for 200 OK
    test:assertEquals(actual = response.statusCode, expected = http:STATUS_OK);
    // Check that the response body contains the expected books
    test:assertEquals(actual = check response.getJsonPayload(), expected = books.toArray());
}

@test:Config {
    dependsOn: [getAllBooksTest]
}

function getBookByIdSuccessTest() returns error? {
    string id = "1";
    http:Response response = check bookstoreClient->get("/books/" + id);
    // Check for 200 OK
    test:assertEquals(actual = response.statusCode, expected = http:STATUS_OK);
    // Check that the response body contains the expected book
    test:assertEquals(actual = check response.getJsonPayload(), expected = books[id]);
}

@test:Config {
    dependsOn: [getAllBooksTest]
}

function getBookByIdNotFoundTest() returns error? {
    string id = "999"; // Non-existent book ID
    http:Response response = check bookstoreClient->get("/books/" + id);
    // Check for 404 Not Found
    test:assertEquals(actual = response.statusCode, expected = http:STATUS_NOT_FOUND);
    // Check for the correct JSON error structure
    json expectedError = { message: "Book with ID " + id + " not found." };
    // Check that the response body contains the expected error
    test:assertEquals(actual = check response.getJsonPayload(), expected = expectedError);
}

function beforeFunc2() {
    // Clear the table and reset to initial state
    books.removeAll();
}

@test:Config {
    before: beforeFunc2,
    dependsOn: [getAllBooksTest]
}

function getAllBooksWhenEmptyTest() returns error? {
    http:Response response = check bookstoreClient->get("/books");
    // Check for 200 OK
    test:assertEquals(actual = response.statusCode, expected = http:STATUS_OK);
    // Check that the response body is an empty array
    test:assertEquals(actual = check response.getJsonPayload(), expected = []);
}

@test:Config {
    before: beforeFunc1
}
// Test for a successful deletion (204 No Content)
function deleteBookSuccessTest() returns error? {
    string id = "2";

    http:Response response = check bookstoreClient->delete("/books/" + id);
    // Check for 204 No Content
    test:assertEquals(actual = response.statusCode, expected = http:STATUS_NO_CONTENT);

    // Verify the book is deleted by attempting to get all books and checking the absence of the deleted book
    response = check bookstoreClient->get("/books");
    Book[] remainingBooks = [
        { id: "1", title: "1984", author: "George Orwell", year: 1949 },
        { id: "3", title: "The Great Gatsby", author: "F. Scott Fitzgerald", year: 1925 }
    ];
    test:assertEquals(actual = check response.getJsonPayload(), expected = remainingBooks);
}

@test:Config {
    dependsOn: [deleteBookSuccessTest]
}

function deleteBookNotFoundTest() returns error? {
    string id = "999"; // Non-existent book ID

    http:Response response = check bookstoreClient->delete("/books/" + id);
    // Check for 404 Not Found
    test:assertEquals(actual = response.statusCode, expected = http:STATUS_NOT_FOUND);

    // Check for the correct JSON error structure
    json expectedError = { message: "Book with ID " + id + " not found." };
    // Check that the response body contains the expected error
    test:assertEquals(actual = check response.getJsonPayload(), expected = expectedError);
}