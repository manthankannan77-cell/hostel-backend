const express = require("express");
const cors = require("cors");
const path = require("path");
require("dotenv").config();

const app = express();

// ✅ CORS — must come first
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }),
);

app.use(express.json());
app.use(express.static(path.join(__dirname)));

// ✅ Serve the main HTML page
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "hostel_manage.html"));
});

// ✅ Auth Routes
const { router: authRouter } = require("./routes/auth");
app.use("/api/auth", authRouter);

// ✅ All API Routes
app.use("/api/students", require("./routes/students"));
app.use("/api/rooms", require("./routes/rooms"));
app.use("/api/payments", require("./routes/payments"));
app.use("/api/complaints", require("./routes/complaints"));
app.use("/api/visitors", require("./routes/visitors"));
app.use("/api/blocks", require("./routes/blocks"));
app.use("/api/staff", require("./routes/staff"));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
});
