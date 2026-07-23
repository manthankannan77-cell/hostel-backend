require("dotenv").config();
const bcrypt = require("bcrypt");
const db = require("./db");

async function createAdmin() {
  const name = "Admin";
  const email = "admin@hostel.com";
  const password = "admin123";
  const role = "admin";

  try {
    // Create users table if it doesn't exist
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        role ENUM('admin', 'student') DEFAULT 'student',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    const hashed = await bcrypt.hash(password, 10);
    await db.query(
      "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)",
      [name, email, hashed, role],
    );

    console.log("✅ Admin account created successfully!");
    console.log(`   Email:    ${email}`);
    console.log(`   Password: ${password}`);
    console.log("   ⚠️  Please change the password after first login.");
  } catch (err) {
    if (err.code === "ER_DUP_ENTRY") {
      console.log("ℹ️  Admin account already exists.");
    } else {
      console.error("❌ Error:", err.message);
    }
  }
  process.exit();
}

createAdmin();
