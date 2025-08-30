import ballerina/http;

table<Book> key(id) books = table [
    { id: "1", title: "1984", author: "George Orwell", year: 1949 },
    { id: "2", title: "To Kill a Mockingbird", author: "Harper Lee", year: 1960 },
    { id: "3", title: "The Great Gatsby", author: "F. Scott Fitzgerald", year: 1925 }
];

service /books on new http:Listener(servicePort, config={host: serviceHost}) {

    //curl http://localhost:8080/books
    //Retrieves all the books
    resource function get .() returns Book[]|http:NotFound {
        return books.toArray();
    }

    //curl http://localhost:8080/books/id
    //Retrieve a book by ID
    resource function get [string id]() returns Book|http:NotFound {
        Book? book = books[id];

        // This 'if' block checks if foundBook is actually a Book or if it's nil.
        if book is Book {
            // If it is a Book, it's safe to return it.
            return book;
        } else {
            // If it's nil (not found), we return the http:NotFound status.
            Error err = {message: "Book with ID " + id + " not found."};
            return <http:NotFound>{body: err};
        }
    }

    //curl -X POST http://localhost:8080/books -H "Content-Type: application/json" -d "{\"id\":\"4\",\"title\":\"The Handmaid's Tale\",\"author\":\"Margaret Atwood\",\"year\":1985}"
    //Add a new book
    resource function post.(Book payload) returns http:Created|http:Conflict {
       if books.hasKey(payload.id) {
           Error err = {message: "Book with ID " + payload.id + " already exists."};
            return <http:Conflict>{body: err};
       }
       // Implementation to add a new book
        books.add(payload);
        http:Created response = {
            headers: {Location: "/books/" + payload.id},
            body: payload
        };
        return response;
    }

    //curl -X DELETE -v http://localhost:8080/books/id
    //Delete a book by ID
    resource function delete [string id]() returns http:NoContent|http:NotFound {
        // Implementation to delete a book by ID
        if books.hasKey(id) {
            _ = books.remove(id); 
            return <http:NoContent>{};
        } else {
            Error err = {message: "Book with ID " + id + " not found."};
            return <http:NotFound>{body: err};
        }
    }
}