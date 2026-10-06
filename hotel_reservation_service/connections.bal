import ballerinax/mysql;
import ballerinax/mysql.driver as _;

final mysql:Client dbClient = check new (
    host = dbHost,
    port = dbPort,
    user = dbUser,
    password = dbPassword,
    database = dbName
);
