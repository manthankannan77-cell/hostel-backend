// db.js
const mysql = require("mysql2/promise"); // ✅ promise version
require("dotenv").config();

const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD, // ✅ matches your .env exactly
  database: process.env.DB_NAME,
  port: 3306,
  waitForConnections: true,
  connectionLimit: 10,
});

// Test connection on startup
db.getConnection()
  .then((conn) => {
    console.log("✅ MySQL Connected!");
    conn.release();
  })
  .catch((err) => {
    console.error("❌ DB Connection Failed:", err.message);
  });

module.exports = db;
