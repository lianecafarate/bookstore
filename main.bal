import ballerina/io;

public function main() {
    io:println("---Bookstore API---");
    io:println("Service started at http://", serviceHost, ":", servicePort, "/books");
}