const mysql = require('mysql2');

const pool = mysql.createPool({
  host: 'localhost',       // usually 'localhost'
  user: 'root',            // your MySQL username
  password: 'Ash@@2621',// your MySQL password
  database: 'ecommerce_app', // your database name
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool.promise();
