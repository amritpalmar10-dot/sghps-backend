const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// ============ SQLITE DATABASE ============
const db = new sqlite3.Database('./sghps.db', (err) => {
    if (err) {
        console.error('❌ Database error:', err.message);
    } else {
        console.log('✅ SQLite Database connected');
        createTables();
    }
});

// ============ CREATE TABLES ============
function createTables() {
    // Users Table
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT UNIQUE,
        password_hash TEXT,
        role TEXT CHECK(role IN ('student', 'teacher', 'principal', 'accountant')),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Students Table
    db.run(`CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        admission_no TEXT UNIQUE NOT NULL,
        class TEXT,
        section TEXT,
        roll_no TEXT,
        parent_phone TEXT,
        parent_email TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id)
    )`);

    // Teachers Table
    db.run(`CREATE TABLE IF NOT EXISTS teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        staff_code TEXT UNIQUE NOT NULL,
        designation TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id)
    )`);

    // Principals Table
    db.run(`CREATE TABLE IF NOT EXISTS principals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        principal_code TEXT UNIQUE NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id)
    )`);

    // Accountants Table
    db.run(`CREATE TABLE IF NOT EXISTS accountants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        accountant_code TEXT UNIQUE NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id)
    )`);

    // Attendance Table
    db.run(`CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        date DATE DEFAULT CURRENT_DATE,
        status TEXT CHECK(status IN ('present', 'absent', 'late')),
        teacher_id INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(student_id) REFERENCES students(id),
        FOREIGN KEY(teacher_id) REFERENCES users(id),
        UNIQUE(student_id, date)
    )`);

    // Homework Table
    db.run(`CREATE TABLE IF NOT EXISTS homework (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id INTEGER,
        class TEXT,
        section TEXT,
        subject TEXT,
        title TEXT NOT NULL,
        description TEXT,
        deadline DATE,
        attachment_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(teacher_id) REFERENCES users(id)
    )`);

    // Fees Table
    db.run(`CREATE TABLE IF NOT EXISTS fees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        due_date DATE,
        status TEXT CHECK(status IN ('paid', 'partially_paid', 'due', 'overdue')),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(student_id) REFERENCES students(id)
    )`);

    // Payments Table
    db.run(`CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        amount REAL NOT NULL,
        payment_method TEXT,
        transaction_id TEXT,
        receipt_number TEXT,
        status TEXT,
        payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(student_id) REFERENCES students(id)
    )`);

    // Leaves Table
    db.run(`CREATE TABLE IF NOT EXISTS leaves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        reason TEXT,
        status TEXT CHECK(status IN ('pending', 'approved', 'rejected')),
        approved_at DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(student_id) REFERENCES students(id)
    )`);

    // Timetable Table
    db.run(`CREATE TABLE IF NOT EXISTS timetable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class TEXT,
        section TEXT,
        day TEXT,
        period INTEGER,
        subject TEXT,
        teacher_name TEXT,
        room TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Notifications Table
    db.run(`CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT NOT NULL,
        message TEXT,
        type TEXT,
        priority TEXT,
        is_read INTEGER DEFAULT 0,
        link TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id)
    )`);

    // OTP Requests Table
    db.run(`CREATE TABLE IF NOT EXISTS otp_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        otp TEXT NOT NULL,
        expires_at DATETIME NOT NULL,
        used INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(user_id) REFERENCES users(id)
    )`);

    // Insert Test Data
    insertTestData();
}

// ============ INSERT TEST DATA ============
function insertTestData() {
    // Check if data exists
    db.get(`SELECT COUNT(*) as count FROM users`, (err, row) => {
        if (err) {
            console.error('Error checking data:', err);
            return;
        }
        
        if (row.count > 0) {
            console.log('✅ Test data already exists');
            return;
        }

        // Insert users
        const users = [
            ['Manavjot Singh', 'manavjot@test.com', '9876543210', 'student'],
            ['Navdeep Singh', 'navdeep@test.com', '9876543211', 'teacher'],
            ['Jaskaran Singh', 'jaskaran@test.com', '9876543212', 'principal'],
            ['Amritpal Singh', 'amritpal@test.com', '9876543213', 'accountant']
        ];

        users.forEach((user, index) => {
            db.run(
                `INSERT INTO users (name, email, phone, role) VALUES (?, ?, ?, ?)`,
                user,
                function(err) {
                    if (err) {
                        console.error('Error inserting user:', err);
                        return;
                    }
                    
                    const userId = this.lastID;
                    
                    // Insert role specific data
                    if (user[3] === 'student') {
                        db.run(
                            `INSERT INTO students (user_id, admission_no, class, section, roll_no, parent_phone) 
                             VALUES (?, ?, ?, ?, ?, ?)`,
                            [userId, 'SGHPS-2024-001', 'XII', 'A', '01', '9876543214']
                        );
                    } else if (user[3] === 'teacher') {
                        db.run(
                            `INSERT INTO teachers (user_id, staff_code, designation) VALUES (?, ?, ?)`,
                            [userId, 'TCH-001', 'Senior Teacher']
                        );
                    } else if (user[3] === 'principal') {
                        db.run(
                            `INSERT INTO principals (user_id, principal_code) VALUES (?, ?)`,
                            [userId, 'PR-001']
                        );
                    } else if (user[3] === 'accountant') {
                        db.run(
                            `INSERT INTO accountants (user_id, accountant_code) VALUES (?, ?)`,
                            [userId, 'ACC-001']
                        );
                    }
                }
            );
        });

        // Insert sample data after users
        setTimeout(() => {
            // Sample Fee
            db.run(
                `INSERT INTO fees (student_id, total_amount, paid_amount, due_date, status) 
                 VALUES (1, 50000, 35000, '2024-12-31', 'partially_paid')`
            );

            // Sample Attendance
            const today = new Date();
            for (let i = 0; i < 5; i++) {
                const date = new Date(today);
                date.setDate(date.getDate() - i);
                const status = i === 2 ? 'absent' : 'present';
                db.run(
                    `INSERT INTO attendance (student_id, date, status, teacher_id) 
                     VALUES (1, ?, ?, 2)`,
                    [date.toISOString().split('T')[0], status]
                );
            }

            // Sample Homework
            db.run(
                `INSERT INTO homework (teacher_id, class, section, subject, title, description, deadline) 
                 VALUES (2, 'XII', 'A', 'Mathematics', 'Chapter 5: Calculus', 
                         'Solve all exercises from Chapter 5', '2024-12-20')`
            );

            // Sample Timetable
            const timetable = [
                ['XII', 'A', 'monday', 1, 'Mathematics', 'Navdeep Singh', 'Room 101'],
                ['XII', 'A', 'monday', 2, 'Physics', 'Dr. Sharma', 'Room 102'],
                ['XII', 'A', 'tuesday', 1, 'Chemistry', 'Ms. Gupta', 'Room 103'],
                ['XII', 'A', 'tuesday', 2, 'English', 'Mr. Kumar', 'Room 104']
            ];
            timetable.forEach(t => {
                db.run(
                    `INSERT INTO timetable (class, section, day, period, subject, teacher_name, room) 
                     VALUES (?, ?, ?, ?, ?, ?, ?)`,
                    t
                );
            });

            console.log('✅ Test data inserted successfully');
        }, 500);
    });
}

// ============ MIDDLEWARE ============
app.use(cors());
app.use(express.json());

// ============ AUTH ROUTES ============

// Student Login (Send OTP)
app.post('/api/auth/student/login', async (req, res) => {
    try {
        const { admission_no, phone } = req.body;
        
        if (!admission_no || !phone) {
            return res.status(400).json({ 
                success: false, 
                message: 'Admission number and phone are required' 
            });
        }
        
        db.get(
            `SELECT s.*, u.id as user_id, u.name, u.phone, u.email, u.role 
             FROM students s 
             JOIN users u ON s.user_id = u.id 
             WHERE s.admission_no = ? AND u.phone = ?`,
            [admission_no, phone],
            async (err, student) => {
                if (err || !student) {
                    return res.status(404).json({ 
                        success: false, 
                        message: 'Student not found' 
                    });
                }
                
                const otp = Math.floor(100000 + Math.random() * 900000).toString();
                
                // Delete old OTPs
                db.run(`DELETE FROM otp_requests WHERE user_id = ? AND used = 0`, [student.user_id]);
                
                // Store OTP
                const expiry = new Date();
                expiry.setMinutes(expiry.getMinutes() + 5);
                
                db.run(
                    `INSERT INTO otp_requests (user_id, otp, expires_at) VALUES (?, ?, ?)`,
                    [student.user_id, otp, expiry.toISOString()]
                );
                
                console.log(`📱 OTP for ${student.name}: ${otp}`);
                
                res.json({
                    success: true,
                    message: 'OTP sent to your registered mobile number',
                    userId: student.user_id,
                    testOtp: otp // Remove in production
                });
            }
        );
        
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// Verify OTP
app.post('/api/auth/verify-otp', async (req, res) => {
    try {
        const { userId, otp } = req.body;
        
        if (!userId || !otp) {
            return res.status(400).json({ 
                success: false, 
                message: 'User ID and OTP are required' 
            });
        }
        
        db.get(
            `SELECT * FROM otp_requests 
             WHERE user_id = ? AND otp = ? 
             AND expires_at > datetime('now') AND used = 0`,
            [userId, otp],
            (err, otpRecord) => {
                if (err || !otpRecord) {
                    return res.status(401).json({ 
                        success: false, 
                        message: 'Invalid or expired OTP' 
                    });
                }
                
                db.run(`UPDATE otp_requests SET used = 1 WHERE id = ?`, [otpRecord.id]);
                
                db.get(
                    `SELECT id, name, email, phone, role FROM users WHERE id = ?`,
                    [userId],
                    (err, user) => {
                        if (err || !user) {
                            return res.status(404).json({ 
                                success: false, 
                                message: 'User not found' 
                            });
                        }
                        
                        const token = jwt.sign(
                            { userId: user.id, role: user.role },
                            process.env.JWT_SECRET || 'sghps-secret-key',
                            { expiresIn: '7d' }
                        );
                        
                        res.json({
                            success: true,
                            token,
                            user: {
                                id: user.id,
                                name: user.name,
                                email: user.email,
                                phone: user.phone,
                                role: user.role
                            }
                        });
                    }
                );
            }
        );
        
    } catch (error) {
        console.error('OTP verification error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// Teacher Login
app.post('/api/auth/teacher/login', async (req, res) => {
    try {
        const { staff_code, password } = req.body;
        
        if (!staff_code || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'Staff code and password required' 
            });
        }
        
        db.get(
            `SELECT u.*, t.staff_code FROM teachers t JOIN users u ON t.user_id = u.id WHERE t.staff_code = ?`,
            [staff_code],
            (err, user) => {
                if (err || !user) {
                    return res.status(401).json({ 
                        success: false, 
                        message: 'Invalid staff code' 
                    });
                }
                
                if (password !== staff_code) {
                    return res.status(401).json({ 
                        success: false, 
                        message: 'Invalid password' 
                    });
                }
                
                const token = jwt.sign(
                    { userId: user.id, role: user.role },
                    process.env.JWT_SECRET || 'sghps-secret-key',
                    { expiresIn: '7d' }
                );
                
                res.json({
                    success: true,
                    token,
                    user: {
                        id: user.id,
                        name: user.name,
                        email: user.email,
                        phone: user.phone,
                        role: user.role
                    }
                });
            }
        );
        
    } catch (error) {
        console.error('Teacher login error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// Principal Login
app.post('/api/auth/principal/login', async (req, res) => {
    try {
        const { principal_code, password } = req.body;
        
        if (!principal_code || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'Principal code and password required' 
            });
        }
        
        db.get(
            `SELECT u.*, p.principal_code FROM principals p JOIN users u ON p.user_id = u.id WHERE p.principal_code = ?`,
            [principal_code],
            (err, user) => {
                if (err || !user) {
                    return res.status(401).json({ 
                        success: false, 
                        message: 'Invalid principal code' 
                    });
                }
                
                if (password !== principal_code) {
                    return res.status(401).json({ 
                        success: false, 
                        message: 'Invalid password' 
                    });
                }
                
                const token = jwt.sign(
                    { userId: user.id, role: user.role },
                    process.env.JWT_SECRET || 'sghps-secret-key',
                    { expiresIn: '7d' }
                );
                
                res.json({
                    success: true,
                    token,
                    user: {
                        id: user.id,
                        name: user.name,
                        email: user.email,
                        phone: user.phone,
                        role: user.role
                    }
                });
            }
        );
        
    } catch (error) {
        console.error('Principal login error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// Accountant Login
app.post('/api/auth/accountant/login', async (req, res) => {
    try {
        const { accountant_code, password } = req.body;
        
        if (!accountant_code || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'Accountant code and password required' 
            });
        }
        
        db.get(
            `SELECT u.*, a.accountant_code FROM accountants a JOIN users u ON a.user_id = u.id WHERE a.accountant_code = ?`,
            [accountant_code],
            (err, user) => {
                if (err || !user) {
                    return res.status(401).json({ 
                        success: false, 
                        message: 'Invalid accountant code' 
                    });
                }
                
                if (password !== accountant_code) {
                    return res.status(401).json({ 
                        success: false, 
                        message: 'Invalid password' 
                    });
                }
                
                const token = jwt.sign(
                    { userId: user.id, role: user.role },
                    process.env.JWT_SECRET || 'sghps-secret-key',
                    { expiresIn: '7d' }
                );
                
                res.json({
                    success: true,
                    token,
                    user: {
                        id: user.id,
                        name: user.name,
                        email: user.email,
                        phone: user.phone,
                        role: user.role
                    }
                });
            }
        );
        
    } catch (error) {
        console.error('Accountant login error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// ============ STUDENT ROUTES ============

// Get Student Profile
app.get('/api/students/profile', verifyToken, (req, res) => {
    const userId = req.user.userId;
    
    db.get(
        `SELECT s.*, u.name, u.email, u.phone, u.role 
         FROM students s JOIN users u ON s.user_id = u.id WHERE u.id = ?`,
        [userId],
        (err, student) => {
            if (err || !student) {
                return res.status(404).json({ 
                    success: false, 
                    message: 'Student not found' 
                });
            }
            res.json({ success: true, student });
        }
    );
});

// Get Student Attendance
app.get('/api/students/attendance', verifyToken, (req, res) => {
    const userId = req.user.userId;
    
    db.get(`SELECT id FROM students WHERE user_id = ?`, [userId], (err, student) => {
        if (err || !student) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        const studentId = student.id;
        
        db.all(
            `SELECT date, status FROM attendance 
             WHERE student_id = ? 
             AND date >= date('now', '-30 days')
             ORDER BY date DESC`,
            [studentId],
            (err, records) => {
                if (err) {
                    return res.status(500).json({ 
                        success: false, 
                        message: 'Error fetching attendance' 
                    });
                }
                
                const total = records.length;
                const present = records.filter(a => a.status === 'present').length;
                const percentage = total > 0 ? Math.round((present / total) * 100) : 0;
                
                res.json({
                    success: true,
                    attendance: {
                        percentage,
                        total,
                        present,
                        absent: total - present,
                        records
                    }
                });
            }
        );
    });
});

// Get Student Fees
app.get('/api/students/fees', verifyToken, (req, res) => {
    const userId = req.user.userId;
    
    db.get(`SELECT id FROM students WHERE user_id = ?`, [userId], (err, student) => {
        if (err || !student) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        db.all(
            `SELECT * FROM fees WHERE student_id = ? ORDER BY created_at DESC`,
            [student.id],
            (err, fees) => {
                res.json({ success: true, fees });
            }
        );
    });
});

// Get Student Homework
app.get('/api/students/homework', verifyToken, (req, res) => {
    const userId = req.user.userId;
    
    db.get(
        `SELECT class, section FROM students WHERE user_id = ?`,
        [userId],
        (err, student) => {
            if (err || !student) {
                return res.status(404).json({ 
                    success: false, 
                    message: 'Student not found' 
                });
            }
            
            db.all(
                `SELECT h.*, u.name as teacher_name 
                 FROM homework h 
                 JOIN users u ON h.teacher_id = u.id 
                 WHERE h.class = ? AND h.section = ? 
                 ORDER BY h.deadline ASC`,
                [student.class, student.section],
                (err, homework) => {
                    res.json({ success: true, homework });
                }
            );
        }
    );
});

// Apply Leave
app.post('/api/students/leave', verifyToken, (req, res) => {
    const userId = req.user.userId;
    const { start_date, end_date, reason } = req.body;
    
    if (!start_date || !end_date || !reason) {
        return res.status(400).json({ 
            success: false, 
            message: 'All fields are required' 
        });
    }
    
    db.get(`SELECT id FROM students WHERE user_id = ?`, [userId], (err, student) => {
        if (err || !student) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        db.run(
            `INSERT INTO leaves (student_id, start_date, end_date, reason, status) 
             VALUES (?, ?, ?, ?, 'pending')`,
            [student.id, start_date, end_date, reason],
            function(err) {
                if (err) {
                    return res.status(500).json({ 
                        success: false, 
                        message: 'Error applying leave' 
                    });
                }
                
                res.json({
                    success: true,
                    message: 'Leave application submitted successfully',
                    leaveId: this.lastID
                });
            }
        );
    });
});

// ============ PRINCIPAL ROUTES ============

// Get School Statistics
app.get('/api/principal/statistics', verifyToken, checkRole(['principal']), (req, res) => {
    db.get(`SELECT COUNT(*) as total_students FROM students`, (err, students) => {
        db.get(`SELECT COUNT(*) as total_teachers FROM teachers`, (err, teachers) => {
            db.get(`SELECT COUNT(DISTINCT class) as total_classes FROM students`, (err, classes) => {
                db.get(
                    `SELECT COUNT(*) as present FROM attendance 
                     WHERE date = date('now') AND status = 'present'`,
                    (err, attendance) => {
                        res.json({
                            success: true,
                            statistics: {
                                totalStudents: students ? students.total_students : 0,
                                totalTeachers: teachers ? teachers.total_teachers : 0,
                                totalClasses: classes ? classes.total_classes : 0,
                                todayPresent: attendance ? attendance.present : 0
                            }
                        });
                    }
                );
            });
        });
    });
});

// ============ MIDDLEWARE FUNCTIONS ============

function verifyToken(req, res, next) {
    const token = req.headers['authorization']?.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({ success: false, message: 'No token provided' });
    }
    
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'sghps-secret-key');
        req.user = decoded;
        next();
    } catch (error) {
        return res.status(401).json({ success: false, message: 'Invalid token' });
    }
}

function checkRole(roles) {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ success: false, message: 'Unauthorized' });
        }
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ success: false, message: 'Access denied' });
        }
        next();
    };
}

// ============ HEALTH CHECK ============
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'SGHPS Backend Running (SQLite)',
        time: new Date().toISOString()
    });
});

// ============ START SERVER ============
app.listen(PORT, () => {
    console.log(`✅ SGHPS Backend running on http://localhost:${PORT}`);
    console.log(`📚 Health: http://localhost:${PORT}/api/health`);
    console.log(`👨‍🎓 Student Login: POST /api/auth/student/login`);
    console.log(`📱 Database: sghps.db (SQLite)`);
});