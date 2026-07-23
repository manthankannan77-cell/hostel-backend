CREATE DATABASE hostel_db;
USE hostel_db;

CREATE TABLE block (
    block_id CHAR(1) PRIMARY KEY,
    block_name VARCHAR(50) NOT NULL,
    total_floors INT NOT NULL,
    total_rooms INT NOT NULL
);

CREATE TABLE staff (
    staff_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    mobile VARCHAR(15) NOT NULL,
    role ENUM('Warden', 'Assistant Warden', 'Helper') NOT NULL,
    block_id CHAR(1),
    FOREIGN KEY (block_id) REFERENCES block(block_id) ON DELETE SET NULL
);

CREATE TABLE room (
    room_no VARCHAR(10) PRIMARY KEY,
    block_id CHAR(1) NOT NULL,
    floor INT NOT NULL,
    type ENUM('Single', 'Double', 'Triple') NOT NULL,
    capacity INT NOT NULL,
    status ENUM('available', 'occupied', 'maintenance') DEFAULT 'available',
    FOREIGN KEY (block_id) REFERENCES block(block_id) ON DELETE RESTRICT
);

CREATE TABLE student (
    usn VARCHAR(15) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    mobile VARCHAR(15) NOT NULL,
    course VARCHAR(50) NOT NULL,
    year ENUM('1st', '2nd', '3rd', '4th') NOT NULL,
    room_no VARCHAR(10),
    fee_status ENUM('paid', 'unpaid', 'pending') DEFAULT 'pending',
    joining_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (room_no) REFERENCES room(room_no) ON DELETE SET NULL
);

CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    usn VARCHAR(15) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    month VARCHAR(20) NOT NULL,
    due_date DATE NOT NULL,
    paid_date DATE,
    mode ENUM('Cash', 'UPI', 'Bank Transfer', 'Card') NOT NULL,
    txn_id VARCHAR(50),
    status ENUM('paid', 'unpaid', 'pending') DEFAULT 'pending',
    FOREIGN KEY (usn) REFERENCES student(usn) ON DELETE CASCADE
);

CREATE TABLE complaint (
    complaint_id INT AUTO_INCREMENT PRIMARY KEY,
    usn VARCHAR(15) NOT NULL,
    room_no VARCHAR(10) NOT NULL,
    category ENUM('Electrical', 'Plumbing', 'Furniture', 'Cleaning', 'Internet', 'Other') NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    priority ENUM('Low', 'Medium', 'High') DEFAULT 'Low',
    status ENUM('open', 'in-progress', 'resolved') DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (usn) REFERENCES student(usn) ON DELETE CASCADE,
    FOREIGN KEY (room_no) REFERENCES room(room_no) ON DELETE CASCADE
);

CREATE TABLE visitor (
    visitor_id INT AUTO_INCREMENT PRIMARY KEY,
    visitor_name VARCHAR(100) NOT NULL,
    visitor_mobile VARCHAR(15) NOT NULL,
    student_usn VARCHAR(15) NOT NULL,
    room_no VARCHAR(10) NOT NULL,
    purpose ENUM('Personal', 'Academic', 'Family', 'Other') NOT NULL,
    in_time TIME NOT NULL,
    out_time TIME,
    visit_date DATE DEFAULT (CURRENT_DATE),
    status ENUM('in', 'out') DEFAULT 'in',
    FOREIGN KEY (student_usn) REFERENCES student(usn) ON DELETE CASCADE,
    FOREIGN KEY (room_no) REFERENCES room(room_no) ON DELETE CASCADE
);

-- Triggers
DELIMITER //

CREATE TRIGGER trg_room_occupied
AFTER INSERT ON student FOR EACH ROW
BEGIN
    IF NEW.room_no IS NOT NULL THEN
        UPDATE room SET status = 'occupied' WHERE room_no = NEW.room_no;
    END IF;
END;//

CREATE TRIGGER trg_room_available
AFTER DELETE ON student FOR EACH ROW
BEGIN
    DECLARE student_count INT;
    SELECT COUNT(*) INTO student_count FROM student WHERE room_no = OLD.room_no;
    IF student_count = 0 THEN
        UPDATE room SET status = 'available' WHERE room_no = OLD.room_no;
    END IF;
END;//

CREATE TRIGGER trg_complaint_resolved
BEFORE UPDATE ON complaint FOR EACH ROW
BEGIN
    IF NEW.status = 'resolved' AND OLD.status != 'resolved' THEN
        SET NEW.resolved_at = NOW();
    END IF;
END;//

CREATE TRIGGER trg_update_fee_status
AFTER INSERT ON payment FOR EACH ROW
BEGIN
    IF NEW.status = 'paid' THEN
        UPDATE student SET fee_status = 'paid' WHERE usn = NEW.usn;
    END IF;
END;//

DELIMITER ;

-- Views
CREATE VIEW v_room_occupancy AS
SELECT r.room_no, r.block_id, r.type, r.capacity,
       COUNT(s.usn) AS current_occupants, r.status
FROM room r LEFT JOIN student s ON r.room_no = s.room_no
GROUP BY r.room_no, r.block_id, r.type, r.capacity, r.status;

CREATE VIEW v_fee_defaulters AS
SELECT s.usn, s.name, s.mobile, s.room_no, p.amount, p.due_date, p.month
FROM student s JOIN payment p ON s.usn = p.usn
WHERE p.status IN ('unpaid', 'pending') AND p.due_date < CURRENT_DATE;

CREATE VIEW v_active_visitors AS
SELECT v.visitor_name, v.visitor_mobile, v.purpose,
       s.name AS student_name, v.room_no, v.in_time, v.visit_date
FROM visitor v JOIN student s ON v.student_usn = s.usn
WHERE v.status = 'in';

-- Stored Procedure
DELIMITER //
CREATE PROCEDURE sp_admit_student(
    IN p_usn VARCHAR(15), IN p_name VARCHAR(100), IN p_email VARCHAR(100),
    IN p_mobile VARCHAR(15), IN p_course VARCHAR(50), IN p_year VARCHAR(10),
    IN p_room_no VARCHAR(10)
)
BEGIN
    DECLARE room_capacity INT;
    DECLARE current_count INT;
    SELECT capacity INTO room_capacity FROM room WHERE room_no = p_room_no;
    SELECT COUNT(*) INTO current_count FROM student WHERE room_no = p_room_no;
    IF current_count >= room_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room is already at full capacity';
    ELSE
        INSERT INTO student (usn, name, email, mobile, course, year, room_no)
        VALUES (p_usn, p_name, p_email, p_mobile, p_course, p_year, p_room_no);
    END IF;
END;//
DELIMITER ;

-- Sample Data
INSERT INTO block VALUES
('A','Block A',4,20),('B','Block B',4,20),('C','Block C',4,20),('D','Block D',4,20);

INSERT INTO staff VALUES
('S001','Ramesh Kumar','ramesh@hostel.com','9876543210','Warden','A'),
('S002','Suresh Patil','suresh@hostel.com','9876543211','Warden','B'),
('S003','Mahesh Rao','mahesh@hostel.com','9876543212','Assistant Warden','C'),
('S004','Ganesh Nair','ganesh@hostel.com','9876543213','Warden','D');

INSERT INTO room VALUES
('A-101','A',1,'Single',1,'available'),('A-102','A',1,'Double',2,'available'),
('A-103','A',1,'Triple',3,'available'),('A-201','A',2,'Single',1,'available'),
('B-101','B',1,'Single',1,'available'),('B-102','B',1,'Double',2,'available'),
('C-101','C',1,'Single',1,'available'),('C-102','C',1,'Double',2,'available'),
('D-101','D',1,'Single',1,'available'),('D-102','D',1,'Double',2,'available');

INSERT INTO student VALUES
('1NI24CS001','Kiran BP','kiran@student.com','7090079437','ISE','1st','A-101','paid','2024-08-01'),
('1NI24CS002','Arjun Sharma','arjun@student.com','9845012345','CSE','2nd','A-102','pending','2024-08-01'),
('1NI24CS003','Rahul Verma','rahul@student.com','9845023456','ECE','1st','A-102','paid','2024-08-01'),
('1NI24CS004','Amit Singh','amit@student.com','9845034567','ME','3rd','B-101','unpaid','2024-08-01'),
('1NI24CS005','Vijay Kumar','vijay@student.com','9845045678','CE','2nd','B-102','paid','2024-08-01'),
('1NI24CS006','Rohit Patil','rohit@student.com','9845056789','ISE','4th','C-101','pending','2024-08-01'),
('1NI24CS007','Suraj Nair','suraj@student.com','9845067890','CSE','1st','C-102','paid','2024-08-01'),
('1NI24CS008','Deepak Rao','deepak@student.com','9845078901','ECE','3rd','D-101','unpaid','2024-08-01');

INSERT INTO payment VALUES
(1,'1NI24CS001',8000.00,'August 2024','2024-08-10','2024-08-05','UPI','TXN001','paid'),
(2,'1NI24CS002',8000.00,'August 2024','2024-08-10',NULL,'Cash',NULL,'pending'),
(3,'1NI24CS003',8000.00,'August 2024','2024-08-10','2024-08-07','Bank Transfer','TXN003','paid'),
(4,'1NI24CS004',8000.00,'August 2024','2024-08-10',NULL,'Cash',NULL,'unpaid'),
(5,'1NI24CS005',8000.00,'August 2024','2024-08-10','2024-08-09','Card','TXN005','paid');

INSERT INTO complaint VALUES
(1,'1NI24CS002','A-102','Electrical','Fan not working','Ceiling fan stopped working','High','open',NOW(),NULL),
(2,'1NI24CS004','B-101','Plumbing','Tap leaking','Bathroom tap is leaking','Medium','open',NOW(),NULL),
(3,'1NI24CS006','C-101','Internet','No WiFi','WiFi not working since 2 days','High','open',NOW(),NULL),
(4,'1NI24CS001','A-101','Furniture','Chair broken','Study chair leg is broken','Low','resolved',NOW(),NOW());

INSERT INTO visitor VALUES
(1,'Ramesh BP','9900011111','1NI24CS001','A-101','Family','10:00:00',NULL,CURRENT_DATE,'in'),
(2,'Sunita Sharma','9900022222','1NI24CS002','A-102','Personal','11:30:00','13:00:00',CURRENT_DATE,'out'),
(3,'Mohan Verma','9900033333','1NI24CS003','A-102','Academic','14:00:00',NULL,CURRENT_DATE,'in');