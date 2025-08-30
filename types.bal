public type Error record {
    string message;
};
public type Book record {|
    readonly string id;
    string title;
    string author;
    int year;
|};