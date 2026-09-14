const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const sqlite3 = require('sqlite3').verbose();
require('dotenv').config();

const app = express();
const PORT = 5001;

// ============ DATABASE ============
const db = new sqlite3.Database('./sghps.db');

// ============ CREATE TABLES ============
db.serialize(() => {
    console.log('📦 Creating tables...');

    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, email TEXT, phone TEXT, role TEXT
    )`);
    
    db.run(`CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER, admission_no TEXT UNIQUE, class TEXT, section TEXT,
        roll_no TEXT, parent_name TEXT, parent_phone TEXT, parent_email TEXT,
        address TEXT, dob TEXT, gender TEXT
    )`);
    
    db.run(`CREATE TABLE IF NOT EXISTS teachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER, staff_code TEXT UNIQUE, designation TEXT,
        subject TEXT, is_class_incharge INTEGER DEFAULT 0,
        incharge_class TEXT, incharge_section TEXT, salary REAL DEFAULT 0
    )`);
    
    db.run(`CREATE TABLE IF NOT EXISTS principals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER, principal_code TEXT UNIQUE
    )`);
    
    db.run(`CREATE TABLE IF NOT EXISTS accountants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER, accountant_code TEXT UNIQUE
    )`);
    
    db.run(`CREATE TABLE IF NOT EXISTS otp_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER, otp TEXT, expires_at TEXT, used INTEGER DEFAULT 0
    )`);
    
    db.run(`CREATE TABLE IF NOT EXISTS leaves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER, start_date TEXT, end_date TEXT,
        reason TEXT, status TEXT DEFAULT 'pending', approved_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )`);
    
    db.run(`CREATE TABLE IF NOT EXISTS staff_leaves (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER, role TEXT, start_date TEXT, end_date TEXT,
        reason TEXT, status TEXT DEFAULT 'pending', approved_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS fees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER UNIQUE, total_amount REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0, due_date TEXT, status TEXT DEFAULT 'due',
        last_updated TEXT DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER, amount REAL, method TEXT,
        transaction_id TEXT, receipt_number TEXT, notes TEXT,
        recorded_by INTEGER, payment_date TEXT DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS fee_structure (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class TEXT UNIQUE, total_fee REAL, term1 REAL, term2 REAL, term3 REAL
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER, action TEXT, entity TEXT, entity_id INTEGER,
        field_changed TEXT, old_value TEXT, new_value TEXT, reason TEXT,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER,
        date TEXT,
        status TEXT CHECK(status IN ('present', 'absent', 'late')),
        teacher_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(student_id, date)
    )`);

    // ✅ HOMEWORK TABLE with homework_date
    db.run(`CREATE TABLE IF NOT EXISTS homework (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id INTEGER,
        class TEXT,
        section TEXT,
        subject TEXT,
        title TEXT,
        description TEXT,
        homework_date TEXT,             -- ✅ YYYY-MM-DD
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS homework_submissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        homework_id INTEGER,
        student_id INTEGER,
        submitted_at TEXT DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'submitted',
        UNIQUE(homework_id, student_id)
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    event_date TEXT NOT NULL,
    event_time TEXT,
    location TEXT,
    type TEXT DEFAULT 'event',
    priority TEXT DEFAULT 'normal',
    created_by INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
)`);

    db.run(`CREATE TABLE IF NOT EXISTS exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, subject TEXT, class TEXT, section TEXT,
        exam_date TEXT, start_time TEXT, duration INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )`);
    
    console.log('✅ All tables created');
});

// ============ INSERT TEST DATA ============
setTimeout(() => {
    db.get(`SELECT COUNT(*) as count FROM users`, (err, row) => {
        if (row.count === 0) {
            console.log('📥 Inserting test data...');

            db.run(`INSERT INTO users (name, email, phone, role) VALUES 
                ('Manavjot Singh', 'manavjot@test.com', '9876543210', 'student'),
                ('Navdeep Singh', 'navdeep@test.com', '9876543211', 'teacher'),
                ('Jaskaran Singh', 'jaskaran@test.com', '9876543212', 'principal'),
                ('Amritpal Singh', 'amritpal@test.com', '9876543213', 'accountant')`);
            
            db.run(`INSERT INTO students (user_id, admission_no, class, section, roll_no, parent_name, parent_phone) VALUES 
                (1, 'SGHPS-2024-001', 'XII', 'A', '01', 'Gurpreet Singh', '9876543214')`);
            
            db.run(`INSERT INTO teachers (user_id, staff_code, designation, subject, is_class_incharge, incharge_class, incharge_section, salary) 
                VALUES (2, 'TCH-001', 'Senior Teacher', 'Mathematics', 1, 'XII', 'A', 50000)`);
            
            db.run(`INSERT INTO principals (user_id, principal_code) VALUES (3, 'PR-001')`);
            db.run(`INSERT INTO accountants (user_id, accountant_code) VALUES (4, 'ACC-001')`);
            
            db.run(`INSERT INTO fees (student_id, total_amount, paid_amount, due_date, status) 
                VALUES (1, 50000, 35000, '2026-12-31', 'partially_paid')`);
            
            db.run(`INSERT INTO payments (student_id, amount, method, receipt_number) VALUES 
                (1, 20000, 'Online', 'RCP001'), (1, 15000, 'Cash', 'RCP002')`);
            
            db.run(`INSERT INTO fee_structure (class, total_fee, term1, term2, term3) VALUES 
                ('XII', 50000, 20000, 15000, 15000),
                ('XI', 45000, 18000, 15000, 12000),
                ('X', 40000, 15000, 13000, 12000)`);
            
            // Sample attendance (last 30 days)
            for (let i = 0; i < 30; i++) {
                const date = new Date();
                date.setDate(date.getDate() - i);
                const dateStr = date.toISOString().split('T')[0];
                const status = i % 7 === 0 ? 'absent' : (i % 11 === 0 ? 'late' : 'present');
                
                db.run(`INSERT INTO attendance (student_id, date, status, teacher_id) 
                        VALUES (1, ?, ?, 2)`, [dateStr, status]);
            }
            
            // ✅ TODAY's homework
            const today = new Date().toISOString().split('T')[0];
            const yesterday = new Date();
            yesterday.setDate(yesterday.getDate() - 1);
            const yesterdayStr = yesterday.toISOString().split('T')[0];
            const twoDaysAgo = new Date();
            twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
            const twoDaysAgoStr = twoDaysAgo.toISOString().split('T')[0];
            
            // Today's homework
            db.run(`INSERT INTO homework (teacher_id, class, section, subject, title, description, homework_date) VALUES 
                (2, 'XII', 'A', 'Mathematics', 'Chapter 5: Calculus', 'Solve exercises 1-10 from NCERT', ?),
                (2, 'XII', 'A', 'Physics', 'Laws of Motion', 'Complete numerical problems', ?)`,
                [today, today]);
            
            // Yesterday's homework
            db.run(`INSERT INTO homework (teacher_id, class, section, subject, title, description, homework_date) VALUES 
                (2, 'XII', 'A', 'Mathematics', 'Chapter 4: Integrals', 'Practice integration problems', ?),
                (2, 'XII', 'A', 'Chemistry', 'Chemical Bonding', 'Revise notes', ?)`,
                [yesterdayStr, yesterdayStr]);
            
            // 2 days ago
            db.run(`INSERT INTO homework (teacher_id, class, section, subject, title, description, homework_date) VALUES 
                (2, 'XII', 'A', 'English', 'Essay Writing', 'Write 500 words on "My School"', ?)`,
                [twoDaysAgoStr]);
            
            // Sample events
            const tomorrow = new Date();
            tomorrow.setDate(tomorrow.getDate() + 1);
            
            db.run(`INSERT INTO events (title, description, event_date, type) VALUES 
                ('Annual Sports Day', 'Annual sports competition', ?, 'event'),
                ('Parent Teacher Meeting', 'PTM for all classes', ?, 'ptm')`,
                [tomorrow.toISOString().split('T')[0],
                 tomorrow.toISOString().split('T')[0]]);
            
            console.log('✅ Test data inserted');
        }
    });
}, 500);

console.log('✅ Database ready');

// ============ MIDDLEWARE ============
app.use(cors());
app.use(express.json());

// ============ AUTH MIDDLEWARE ============
function verifyToken(req, res, next) {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ success: false, message: 'No token' });
    try {
        req.user = jwt.verify(token, process.env.JWT_SECRET || 'sghps-secret-key');
        next();
    } catch (error) {
        res.status(401).json({ success: false, message: 'Invalid token' });
    }
}

function checkRole(roles) {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ success: false, message: 'Access denied' });
        }
        next();
    };
}

// ============ HEALTH CHECK ============
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', message: 'SGHPS Backend Running!' });
});

// ============================================
// ========== AUTH APIs ==========
// ============================================

app.post('/api/auth/student/login', (req, res) => {
    const { admission_no, phone } = req.body;
    
    db.get(
        `SELECT u.id as user_id, u.name FROM students s 
         JOIN users u ON s.user_id = u.id 
         WHERE s.admission_no = ? AND u.phone = ?`,
        [admission_no, phone],
        (err, student) => {
            if (err || !student) return res.status(404).json({ success: false, message: 'Student not found' });
            
            const otp = Math.floor(100000 + Math.random() * 900000);
            const expires = new Date(Date.now() + 5 * 60000).toISOString();
            
            db.run(
                `INSERT INTO otp_requests (user_id, otp, expires_at) VALUES (?, ?, ?)`,
                [student.user_id, otp.toString(), expires],
                function(err) {
                    console.log(`📱 OTP for ${student.name}: ${otp}`);
                    res.json({ success: true, message: 'OTP sent', userId: student.user_id, testOtp: otp });
                }
            );
        }
    );
});

app.post('/api/auth/verify-otp', (req, res) => {
    const { userId, otp } = req.body;
    
    if (!userId || !otp) {
        return res.status(400).json({ success: false, message: 'User ID and OTP required' });
    }
    
    db.get(
        `SELECT * FROM otp_requests 
         WHERE user_id = ? AND otp = ? AND used = 0
         ORDER BY id DESC LIMIT 1`,
        [userId, otp.toString()],
        (err, record) => {
            if (err || !record) return res.status(401).json({ success: false, message: 'Invalid OTP' });
            
            db.run(`UPDATE otp_requests SET used = 1 WHERE id = ?`, [record.id]);
            
            db.get(`SELECT id, name, email, phone, role FROM users WHERE id = ?`, [userId], (err, user) => {
                const token = jwt.sign(
                    { userId: user.id, role: user.role },
                    process.env.JWT_SECRET || 'sghps-secret-key',
                    { expiresIn: '7d' }
                );
                res.json({ success: true, token, user });
            });
        }
    );
});

app.post('/api/auth/teacher/login', (req, res) => {
    const { staff_code, password } = req.body;
    
    db.get(
        `SELECT t.*, u.id as user_id, u.name, u.email, u.phone, u.role 
         FROM teachers t JOIN users u ON t.user_id = u.id 
         WHERE t.staff_code = ?`,
        [staff_code],
        (err, teacher) => {
            if (err || !teacher || password !== staff_code) {
                return res.status(401).json({ success: false, message: 'Invalid credentials' });
            }
            
            const token = jwt.sign(
                { userId: teacher.user_id, role: teacher.role },
                process.env.JWT_SECRET || 'sghps-secret-key',
                { expiresIn: '7d' }
            );
            
            res.json({
                success: true, token,
                user: {
                    id: teacher.user_id, name: teacher.name,
                    email: teacher.email, phone: teacher.phone, role: teacher.role
                }
            });
        }
    );
});

app.post('/api/auth/principal/login', (req, res) => {
    const { principal_code, password } = req.body;
    
    if (principal_code === 'PR-001' && password === 'PR-001') {
        const token = jwt.sign(
            { userId: 3, role: 'principal' },
            process.env.JWT_SECRET || 'sghps-secret-key',
            { expiresIn: '7d' }
        );
        res.json({
            success: true, token,
            user: { id: 3, name: 'Jaskaran Singh', email: 'jaskaran@test.com', role: 'principal' }
        });
    } else {
        res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
});

app.post('/api/auth/accountant/login', (req, res) => {
    const { accountant_code, password } = req.body;
    
    if (accountant_code === 'ACC-001' && password === 'ACC-001') {
        const token = jwt.sign(
            { userId: 4, role: 'accountant' },
            process.env.JWT_SECRET || 'sghps-secret-key',
            { expiresIn: '7d' }
        );
        res.json({
            success: true, token,
            user: { id: 4, name: 'Amritpal Singh', email: 'amritpal@test.com', role: 'accountant' }
        });
    } else {
        res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
});

// ============================================
// ========== STUDENT APIs ==========
// ============================================

app.get('/api/students/profile', verifyToken, (req, res) => {
    db.get(
        `SELECT s.*, u.name, u.email, u.phone FROM students s 
         JOIN users u ON s.user_id = u.id WHERE u.id = ?`,
        [req.user.userId],
        (err, student) => res.json({ success: true, student })
    );
});

app.get('/api/students/attendance', verifyToken, (req, res) => {
    db.get(`SELECT id FROM students WHERE user_id = ?`, [req.user.userId], (err, student) => {
        if (!student) return res.status(404).json({ success: false });
        
        db.all(
            `SELECT date, status FROM attendance 
             WHERE student_id = ? 
             ORDER BY date DESC LIMIT 30`,
            [student.id],
            (err, records) => {
                const total = records.length;
                const present = records.filter(r => r.status === 'present').length;
                const percentage = total > 0 ? Math.round((present / total) * 100) : 0;
                
                res.json({ success: true, attendance: records, percentage, total, present });
            }
        );
    });
});

app.get('/api/students/attendance-calendar', verifyToken, (req, res) => {
    const { month, year } = req.query;
    
    const currentDate = new Date();
    const m = month || (currentDate.getMonth() + 1);
    const y = year || currentDate.getFullYear();
    
    const startDate = `${y}-${m.toString().padStart(2, '0')}-01`;
    const endDate = `${y}-${m.toString().padStart(2, '0')}-31`;
    
    db.get(`SELECT id FROM students WHERE user_id = ?`, [req.user.userId], (err, student) => {
        if (!student) return res.status(404).json({ success: false });
        
        db.all(
            `SELECT date, status FROM attendance 
             WHERE student_id = ? AND date BETWEEN ? AND ?
             ORDER BY date`,
            [student.id, startDate, endDate],
            (err, records) => {
                const total = records.length;
                const present = records.filter(r => r.status === 'present').length;
                const absent = records.filter(r => r.status === 'absent').length;
                const late = records.filter(r => r.status === 'late').length;
                const percentage = total > 0 ? Math.round((present / total) * 100) : 0;
                
                res.json({
                    success: true,
                    month: parseInt(m),
                    year: parseInt(y),
                    records: records,
                    stats: { total, present, absent, late, percentage }
                });
            }
        );
    });
});

app.get('/api/students/fees', verifyToken, (req, res) => {
    db.get(`SELECT id FROM students WHERE user_id = ?`, [req.user.userId], (err, student) => {
        if (!student) return res.status(404).json({ success: false });
        
        db.get(`SELECT * FROM fees WHERE student_id = ?`, [student.id], (err, fee) => {
            db.all(`SELECT * FROM payments WHERE student_id = ? ORDER BY payment_date DESC`, [student.id], (err, payments) => {
                res.json({
                    success: true,
                    fees: {
                        total: fee?.total_amount || 0,
                        paid: fee?.paid_amount || 0,
                        due: (fee?.total_amount || 0) - (fee?.paid_amount || 0),
                        due_date: fee?.due_date || 'N/A',
                        status: fee?.status || 'due',
                        history: payments || [],
                        payment_url: 'https://sghps.edu.in/pay-fees'
                    }
                });
            });
        });
    });
});

// ✅ TODAY'S HOMEWORK (Student)
app.get('/api/students/homework', verifyToken, (req, res) => {
    db.get(
        `SELECT class, section FROM students WHERE user_id = ?`,
        [req.user.userId],
        (err, student) => {
            if (!student) return res.status(404).json({ success: false });
            
            const today = new Date().toISOString().split('T')[0];
            
            db.all(
                `SELECT h.*, u.name as teacher_name,
                        (SELECT COUNT(*) FROM homework_submissions 
                         WHERE homework_id = h.id AND student_id = ?) as is_submitted
                 FROM homework h
                 JOIN users u ON h.teacher_id = u.id
                 WHERE h.class = ? AND h.section = ?
                 AND h.homework_date = ?
                 ORDER BY h.created_at DESC`,
                [req.user.userId, student.class, student.section, today],
                (err, homework) => {
                    if (err) return res.status(500).json({ success: false });
                    res.json({ success: true, homework: homework || [], date: today });
                }
            );
        }
    );
});

// ✅ HOMEWORK HISTORY (Student)
app.get('/api/students/homework-history', verifyToken, (req, res) => {
    db.get(
        `SELECT class, section FROM students WHERE user_id = ?`,
        [req.user.userId],
        (err, student) => {
            if (!student) return res.status(404).json({ success: false });
            
            const today = new Date().toISOString().split('T')[0];
            
            db.all(
                `SELECT h.*, u.name as teacher_name,
                        (SELECT COUNT(*) FROM homework_submissions 
                         WHERE homework_id = h.id AND student_id = ?) as is_submitted
                 FROM homework h
                 JOIN users u ON h.teacher_id = u.id
                 WHERE h.class = ? AND h.section = ?
                 AND h.homework_date < ?
                 ORDER BY h.homework_date DESC, h.created_at DESC
                 LIMIT 100`,
                [req.user.userId, student.class, student.section, today],
                (err, homework) => {
                    if (err) return res.status(500).json({ success: false });
                    res.json({ success: true, homework: homework || [], count: homework.length });
                }
            );
        }
    );
});

// ✅ Submit Homework
app.post('/api/students/homework/:homeworkId/submit', verifyToken, (req, res) => {
    const { homeworkId } = req.params;
    const { content } = req.body;
    
    db.get(`SELECT id FROM students WHERE user_id = ?`, [req.user.userId], (err, student) => {
        if (!student) return res.status(404).json({ success: false });
        
        db.run(
            `INSERT OR REPLACE INTO homework_submissions (homework_id, student_id, status) 
             VALUES (?, ?, 'submitted')`,
            [homeworkId, student.id],
            function(err) {
                if (err) return res.status(500).json({ success: false });
                res.json({ success: true, message: 'Homework submitted!' });
            }
        );
    });
});

app.get('/api/students/results', (req, res) => {
    res.json({
        success: true,
        results: [
            { id: 1, exam_name: 'Mid Term', subject: 'Mathematics', marks: 85, total: 100, grade: 'A' },
        ]
    });
});

app.get('/api/students/timetable', (req, res) => {
    res.json({
        success: true,
        timetable: [
            { day: 'Monday', period: 1, subject: 'Mathematics', teacher: 'Navdeep Singh', room: '101' },
        ]
    });
});

app.get('/api/students/events', (req, res) => {
    db.all(`SELECT * FROM events ORDER BY event_date DESC`, (err, events) => {
        res.json({ success: true, events: events || [] });
    });
});

app.post('/api/students/leave', verifyToken, (req, res) => {
    const { start_date, end_date, reason } = req.body;
    
    if (!start_date || !end_date || !reason) {
        return res.status(400).json({ success: false, message: 'All fields required' });
    }
    
    db.get(`SELECT id FROM students WHERE user_id = ?`, [req.user.userId], (err, student) => {
        if (!student) return res.status(404).json({ success: false });
        
        db.run(
            `INSERT INTO leaves (student_id, start_date, end_date, reason, status) 
             VALUES (?, ?, ?, ?, 'pending')`,
            [student.id, start_date, end_date, reason],
            function(err) {
                if (err) return res.status(500).json({ success: false });
                res.json({ success: true, message: 'Leave applied', leave_id: this.lastID });
            }
        );
    });
});

app.get('/api/students/my-leaves', verifyToken, (req, res) => {
    db.get(`SELECT id FROM students WHERE user_id = ?`, [req.user.userId], (err, student) => {
        if (!student) return res.status(404).json({ success: false });
        
        db.all(
            `SELECT * FROM leaves WHERE student_id = ? ORDER BY created_at DESC`,
            [student.id],
            (err, leaves) => {
                res.json({ success: true, leaves: leaves || [] });
            }
        );
    });
});

// ============================================
// ========== TEACHER APIs ==========
// ============================================

app.get('/api/teacher/check-incharge', verifyToken, (req, res) => {
    db.get(
        `SELECT t.*, u.name FROM teachers t 
         JOIN users u ON t.user_id = u.id WHERE u.id = ?`,
        [req.user.userId],
        (err, teacher) => {
            if (!teacher) return res.status(404).json({ success: false });
            
            res.json({
                success: true,
                is_class_incharge: teacher.is_class_incharge === 1,
                incharge_class: teacher.incharge_class || '',
                incharge_section: teacher.incharge_section || '',
                teacher_name: teacher.name
            });
        }
    );
});

app.get('/api/teacher/pending-leaves', verifyToken, checkRole(['teacher']), (req, res) => {
    db.get(
        `SELECT t.* FROM teachers t WHERE t.user_id = ?`,
        [req.user.userId],
        (err, teacher) => {
            if (err || !teacher || teacher.is_class_incharge !== 1) {
                return res.status(403).json({ success: false, message: 'Only class incharge' });
            }
            
            db.all(
                `SELECT l.*, s.admission_no, u.name as student_name, s.class, s.section 
                 FROM leaves l 
                 JOIN students s ON l.student_id = s.id 
                 JOIN users u ON s.user_id = u.id 
                 WHERE s.class = ? AND s.section = ?
                 ORDER BY l.created_at DESC`,
                [teacher.incharge_class, teacher.incharge_section],
                (err, leaves) => {
                    if (err) return res.status(500).json({ success: false });
                    res.json({ success: true, leaves: leaves || [] });
                }
            );
        }
    );
});

app.put('/api/teacher/leave/:leaveId', verifyToken, checkRole(['teacher']), (req, res) => {
    const { leaveId } = req.params;
    const { status } = req.body;
    
    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ success: false, message: 'Invalid status' });
    }
    
    db.run(
        `UPDATE leaves SET status = ?, approved_by = ? WHERE id = ?`,
        [status, req.user.userId, leaveId],
        function(err) {
            if (err) return res.status(500).json({ success: false });
            res.json({ success: true, message: `Leave ${status}` });
        }
    );
});

app.post('/api/teacher/mark-attendance', verifyToken, checkRole(['teacher']), (req, res) => {
    const { class: className, section, date, attendance } = req.body;
    const teacherId = req.user.userId;
    
    if (!className || !section || !date || !attendance) {
        return res.status(400).json({ success: false, message: 'All fields required' });
    }
    
    db.get(`SELECT * FROM teachers WHERE user_id = ?`, [teacherId], (err, teacher) => {
        if (!teacher || teacher.is_class_incharge !== 1) {
            return res.status(403).json({ success: false, message: 'Only class incharge can mark attendance' });
        }
        
        db.run(
            `DELETE FROM attendance WHERE date = ? AND student_id IN 
             (SELECT id FROM students WHERE class = ? AND section = ?)`,
            [date, className, section]
        );
        
        let completed = 0;
        const total = attendance.length;
        
        if (total === 0) {
            return res.json({ success: true, message: 'No records', count: 0 });
        }
        
        attendance.forEach(record => {
            db.run(
                `INSERT INTO attendance (student_id, date, status, teacher_id) 
                 VALUES (?, ?, ?, ?)`,
                [record.student_id, date, record.status, teacherId],
                (err) => {
                    completed++;
                    if (completed === total) {
                        res.json({
                            success: true,
                            message: 'Attendance marked',
                            date: date,
                            count: total
                        });
                    }
                }
            );
        });
    });
});

// ============================================
// ========== EVENTS APIs ==========
// ============================================

// ✅ CREATE EVENT (Principal + Teacher)
app.post('/api/events/create', verifyToken, checkRole(['principal', 'teacher']), (req, res) => {
    const { title, description, event_date, event_time, location, type, priority } = req.body;
    const userId = req.user.userId;
    
    if (!title || !event_date) {
        return res.status(400).json({ success: false, message: 'Title and date required' });
    }
    
    db.run(
        `INSERT INTO events (title, description, event_date, event_time, location, type, priority, created_by) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [title, description || '', event_date, event_time || '', location || '', 
         type || 'event', priority || 'normal', userId],
        function(err) {
            if (err) return res.status(500).json({ success: false, message: 'Error' });
            res.json({
                success: true,
                message: 'Event created successfully',
                event_id: this.lastID
            });
        }
    );
});

// ✅ GET ALL EVENTS (Everyone)
app.get('/api/events', verifyToken, (req, res) => {
    db.all(
        `SELECT e.*, u.name as created_by_name, u.role as created_by_role
         FROM events e
         LEFT JOIN users u ON e.created_by = u.id
         ORDER BY e.event_date DESC`,
        (err, events) => {
            if (err) return res.status(500).json({ success: false });
            res.json({ success: true, events: events || [] });
        }
    );
});

// ✅ GET UPCOMING EVENTS
app.get('/api/events/upcoming', verifyToken, (req, res) => {
    const today = new Date().toISOString().split('T')[0];
    
    db.all(
        `SELECT e.*, u.name as created_by_name, u.role as created_by_role
         FROM events e
         LEFT JOIN users u ON e.created_by = u.id
         WHERE e.event_date >= ?
         ORDER BY e.event_date ASC
         LIMIT 10`,
        [today],
        (err, events) => {
            if (err) return res.status(500).json({ success: false });
            res.json({ success: true, events: events || [] });
        }
    );
});

// ✅ GET EVENTS BY MONTH (Calendar)
app.get('/api/events/calendar', verifyToken, (req, res) => {
    const { month, year } = req.query;
    const currentDate = new Date();
    const m = month || (currentDate.getMonth() + 1);
    const y = year || currentDate.getFullYear();
    
    const startDate = `${y}-${m.toString().padStart(2, '0')}-01`;
    const endDate = `${y}-${m.toString().padStart(2, '0')}-31`;
    
    db.all(
        `SELECT e.*, u.name as created_by_name
         FROM events e
         LEFT JOIN users u ON e.created_by = u.id
         WHERE e.event_date BETWEEN ? AND ?
         ORDER BY e.event_date`,
        [startDate, endDate],
        (err, events) => {
            if (err) return res.status(500).json({ success: false });
            res.json({ success: true, events: events || [], month: parseInt(m), year: parseInt(y) });
        }
    );
});

// ✅ EDIT EVENT (Creator or Principal)
app.put('/api/events/:eventId', verifyToken, checkRole(['principal', 'teacher']), (req, res) => {
    const { eventId } = req.params;
    const { title, description, event_date, event_time, location, type, priority } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;
    
    db.get(`SELECT * FROM events WHERE id = ?`, [eventId], (err, event) => {
        if (!event) return res.status(404).json({ success: false, message: 'Event not found' });
        
        // Only creator or Principal can edit
        if (userRole !== 'principal' && event.created_by !== userId) {
            return res.status(403).json({ success: false, message: 'Not authorized' });
        }
        
        db.run(
            `UPDATE events SET 
                title = COALESCE(?, title),
                description = COALESCE(?, description),
                event_date = COALESCE(?, event_date),
                event_time = COALESCE(?, event_time),
                location = COALESCE(?, location),
                type = COALESCE(?, type),
                priority = COALESCE(?, priority)
             WHERE id = ?`,
            [title, description, event_date, event_time, location, type, priority, eventId],
            function(err) {
                if (err) return res.status(500).json({ success: false });
                res.json({ success: true, message: 'Event updated' });
            }
        );
    });
});

// ✅ DELETE EVENT (Creator or Principal)
app.delete('/api/events/:eventId', verifyToken, checkRole(['principal', 'teacher']), (req, res) => {
    const { eventId } = req.params;
    const userId = req.user.userId;
    const userRole = req.user.role;
    
    db.get(`SELECT * FROM events WHERE id = ?`, [eventId], (err, event) => {
        if (!event) return res.status(404).json({ success: false, message: 'Event not found' });
        
        // Only creator or Principal can delete
        if (userRole !== 'principal' && event.created_by !== userId) {
            return res.status(403).json({ success: false, message: 'Not authorized' });
        }
        
        db.run(`DELETE FROM events WHERE id = ?`, [eventId], function(err) {
            if (err) return res.status(500).json({ success: false });
            res.json({ success: true, message: 'Event deleted' });
        });
    });
});

app.get('/api/attendance/by-date', verifyToken, (req, res) => {
    const { date, class: className, section } = req.query;
    
    if (!date) return res.status(400).json({ success: false, message: 'Date required' });
    
    let query = `
        SELECT a.*, s.admission_no, s.roll_no, u.name as student_name,
               s.class, s.section
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        JOIN users u ON s.user_id = u.id
        WHERE a.date = ?
    `;
    const params = [date];
    
    if (className) { query += ` AND s.class = ?`; params.push(className); }
    if (section) { query += ` AND s.section = ?`; params.push(section); }
    
    query += ` ORDER BY s.roll_no`;
    
    db.all(query, params, (err, records) => {
        res.json({ success: true, attendance: records || [] });
    });
});

app.get('/api/attendance/range', verifyToken, (req, res) => {
    const { start, end, class: className, section } = req.query;
    
    if (!start || !end) return res.status(400).json({ success: false, message: 'Dates required' });
    
    let query = `
        SELECT a.*, s.admission_no, s.roll_no, u.name as student_name
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        JOIN users u ON s.user_id = u.id
        WHERE a.date BETWEEN ? AND ?
    `;
    const params = [start, end];
    
    if (className) { query += ` AND s.class = ?`; params.push(className); }
    if (section) { query += ` AND s.section = ?`; params.push(section); }
    
    query += ` ORDER BY a.date DESC`;
    
    db.all(query, params, (err, records) => {
        res.json({ success: true, attendance: records || [] });
    });
});

app.get('/api/attendance/class-stats', verifyToken, (req, res) => {
    const { class: className, section, month, year } = req.query;
    
    if (!className || !section) {
        return res.status(400).json({ success: false, message: 'Class and section required' });
    }
    
    const currentDate = new Date();
    const m = month || (currentDate.getMonth() + 1);
    const y = year || currentDate.getFullYear();
    
    const startDate = `${y}-${m.toString().padStart(2, '0')}-01`;
    const endDate = `${y}-${m.toString().padStart(2, '0')}-31`;
    
    db.all(
        `SELECT date, 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present,
                SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent,
                SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late
         FROM attendance 
         WHERE student_id IN (SELECT id FROM students WHERE class = ? AND section = ?)
         AND date BETWEEN ? AND ?
         GROUP BY date
         ORDER BY date`,
        [className, section, startDate, endDate],
        (err, stats) => {
            res.json({ success: true, stats: stats || [] });
        }
    );
});

// ✅ CREATE HOMEWORK (Auto today's date)
app.post('/api/teacher/homework', verifyToken, checkRole(['teacher']), (req, res) => {
    const { class: className, section, subject, title, description } = req.body;
    const teacherId = req.user.userId;
    
    if (!className || !section || !subject || !title) {
        return res.status(400).json({ success: false, message: 'Class, section, subject and title required' });
    }
    
    // ✅ AUTO TODAY'S DATE
    const today = new Date().toISOString().split('T')[0];
    
    db.run(
        `INSERT INTO homework (teacher_id, class, section, subject, title, description, homework_date) 
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [teacherId, className, section, subject, title, description || '', today],
        function(err) {
            if (err) return res.status(500).json({ success: false });
            res.json({
                success: true,
                message: 'Homework created for today',
                homework_id: this.lastID,
                date: today,
                expires: 'Midnight 00:00'
            });
        }
    );
});

// ✅ GET TODAY'S HOMEWORK (Teacher)
app.get('/api/teacher/homework', verifyToken, checkRole(['teacher']), (req, res) => {
    db.get(`SELECT * FROM teachers WHERE user_id = ?`, [req.user.userId], (err, teacher) => {
        if (!teacher) return res.status(404).json({ success: false });
        
        const today = new Date().toISOString().split('T')[0];
        
        db.all(
            `SELECT h.*,
                    (SELECT COUNT(*) FROM homework_submissions 
                     WHERE homework_id = h.id) as submissions_count
             FROM homework h
             WHERE h.teacher_id = ?
             AND h.homework_date = ?
             ORDER BY h.created_at DESC`,
            [teacher.id, today],
            (err, homework) => {
                res.json({ success: true, homework: homework || [], date: today });
            }
        );
    });
});

// ✅ GET HOMEWORK HISTORY (Teacher)
app.get('/api/teacher/homework-history', verifyToken, checkRole(['teacher']), (req, res) => {
    db.get(`SELECT * FROM teachers WHERE user_id = ?`, [req.user.userId], (err, teacher) => {
        if (!teacher) return res.status(404).json({ success: false });
        
        const today = new Date().toISOString().split('T')[0];
        
        db.all(
            `SELECT h.*,
                    (SELECT COUNT(*) FROM homework_submissions 
                     WHERE homework_id = h.id) as submissions_count
             FROM homework h
             WHERE h.teacher_id = ?
             AND h.homework_date < ?
             ORDER BY h.homework_date DESC
             LIMIT 100`,
            [teacher.id, today],
            (err, homework) => {
                res.json({ success: true, homework: homework || [] });
            }
        );
    });
});

// ✅ Get submissions for a homework
app.get('/api/teacher/homework/:homeworkId/submissions', verifyToken, checkRole(['teacher']), (req, res) => {
    const { homeworkId } = req.params;
    
    db.all(
        `SELECT hs.*, u.name as student_name, s.admission_no, s.roll_no
         FROM homework_submissions hs
         JOIN students s ON hs.student_id = s.id
         JOIN users u ON s.user_id = u.id
         WHERE hs.homework_id = ?
         ORDER BY s.roll_no`,
        [homeworkId],
        (err, submissions) => {
            res.json({ success: true, submissions: submissions || [] });
        }
    );
});

app.post('/api/teacher/apply-leave', verifyToken, checkRole(['teacher']), (req, res) => {
    const { start_date, end_date, reason } = req.body;
    
    if (!start_date || !end_date || !reason) {
        return res.status(400).json({ success: false, message: 'All fields required' });
    }
    
    db.run(
        `INSERT INTO staff_leaves (user_id, role, start_date, end_date, reason, status) 
         VALUES (?, 'teacher', ?, ?, ?, 'pending')`,
        [req.user.userId, start_date, end_date, reason],
        function(err) {
            if (err) return res.status(500).json({ success: false });
            res.json({ success: true, message: 'Leave request sent to Principal', leave_id: this.lastID });
        }
    );
});

app.get('/api/teacher/my-leaves', verifyToken, checkRole(['teacher']), (req, res) => {
    db.all(
        `SELECT * FROM staff_leaves 
         WHERE user_id = ? AND role = 'teacher'
         ORDER BY created_at DESC`,
        [req.user.userId],
        (err, leaves) => {
            res.json({ success: true, leaves: leaves || [] });
        }
    );
});

// ============================================
// ========== PRINCIPAL APIs ==========
// ============================================

app.get('/api/principal/stats', verifyToken, checkRole(['principal']), (req, res) => {
    db.get(`SELECT COUNT(*) as total FROM students`, (err, students) => {
        db.get(`SELECT COUNT(*) as total FROM teachers`, (err, teachers) => {
            db.get(`SELECT COUNT(DISTINCT class) as total FROM students`, (err, classes) => {
                db.get(`SELECT COUNT(*) as total FROM staff_leaves WHERE status = 'pending'`, (err, staffLeaves) => {
                    db.get(`SELECT COUNT(*) as total FROM leaves WHERE status = 'pending'`, (err, studentLeaves) => {
                        res.json({
                            success: true,
                            stats: {
                                total_students: students?.total || 0,
                                total_teachers: teachers?.total || 0,
                                total_classes: classes?.total || 0,
                                pending_teacher_leaves: staffLeaves?.total || 0,
                                pending_student_leaves: studentLeaves?.total || 0,
                                today_present: 39,
                                today_absent: 3,
                                attendance_percentage: 92.8,
                            }
                        });
                    });
                });
            });
        });
    });
});

app.get('/api/principal/classes', verifyToken, checkRole(['principal']), (req, res) => {
    const classes = [
        { class: 'XII', section: 'A', total_students: 42, present: 39, absent: 3, attendance: 92.8, class_teacher: 'Navdeep Singh' },
        { class: 'XII', section: 'B', total_students: 40, present: 38, absent: 2, attendance: 95.0, class_teacher: 'Ms. Gupta' },
    ];
    res.json({ success: true, classes });
});

app.get('/api/principal/class/:className/:section', (req, res) => {
    const { className, section } = req.params;
    const students = [
        { id: 1, name: 'Manavjot Singh', roll: '01', admission_no: 'SGHPS-2024-001', attendance: 94, status: 'Active' },
    ];
    res.json({
        success: true,
        class_info: {
            class: className, section: section,
            class_teacher: 'Navdeep Singh',
            total_students: 42, present: 39, absent: 3,
            attendance: 92.8, room: '101',
            subject_teachers: [
                { subject: 'Mathematics', teacher: 'Navdeep Singh' },
            ],
            students: students,
        }
    });
});

app.get('/api/principal/teachers', verifyToken, checkRole(['principal']), (req, res) => {
    db.all(`SELECT t.*, u.name, u.email, u.phone FROM teachers t 
            JOIN users u ON t.user_id = u.id`, (err, teachers) => {
        const formatted = (teachers || []).map(t => ({
            id: t.id, name: t.name, staff_code: t.staff_code,
            subject: t.subject || 'Mathematics',
            designation: t.designation || 'Teacher',
            is_class_incharge: t.is_class_incharge === 1,
            incharge_class: t.incharge_class || '',
            incharge_section: t.incharge_section || '',
            classes_count: 5, students_count: 120,
        }));
        res.json({ success: true, teachers: formatted });
    });
});

app.get('/api/principal/staff-leaves', verifyToken, checkRole(['principal']), (req, res) => {
    db.all(
        `SELECT sl.*, u.name as staff_name, u.phone, u.role
         FROM staff_leaves sl 
         JOIN users u ON sl.user_id = u.id 
         ORDER BY sl.created_at DESC`,
        (err, leaves) => {
            res.json({ success: true, leaves: leaves || [] });
        }
    );
});

app.put('/api/principal/staff-leave/:leaveId', verifyToken, checkRole(['principal']), (req, res) => {
    const { leaveId } = req.params;
    const { status } = req.body;
    
    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ success: false, message: 'Invalid status' });
    }
    
    db.run(
        `UPDATE staff_leaves SET status = ?, approved_by = ? WHERE id = ?`,
        [status, req.user.userId, leaveId],
        function(err) {
            if (err) return res.status(500).json({ success: false });
            res.json({ success: true, message: `Leave ${status}` });
        }
    );
});

app.get('/api/principal/teacher-leaves', verifyToken, checkRole(['principal']), (req, res) => {
    db.all(
        `SELECT l.*, s.admission_no, u.name as student_name, s.class, s.section 
         FROM leaves l 
         JOIN students s ON l.student_id = s.id 
         JOIN users u ON s.user_id = u.id 
         ORDER BY l.created_at DESC`,
        (err, leaves) => {
            res.json({ success: true, leaves: leaves || [] });
        }
    );
});

app.put('/api/principal/teacher-leave/:leaveId', verifyToken, checkRole(['principal']), (req, res) => {
    const { leaveId } = req.params;
    const { status } = req.body;
    
    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ success: false, message: 'Invalid status' });
    }
    
    db.run(`UPDATE leaves SET status = ?, approved_by = ? WHERE id = ?`, 
        [status, req.user.userId, leaveId], function(err) {
        if (err) return res.status(500).json({ success: false });
        res.json({ success: true, message: `Leave ${status}` });
    });
});

// ============================================
// ========== ACCOUNTANT APIs ==========
// ============================================

app.get('/api/accountant/stats', verifyToken, checkRole(['accountant']), (req, res) => {
    db.get(`SELECT COUNT(*) as total FROM students`, (err, students) => {
        db.get(`SELECT COUNT(*) as total FROM teachers`, (err, teachers) => {
            db.get(`SELECT SUM(total_amount) as total FROM fees`, (err, totalFee) => {
                db.get(`SELECT SUM(paid_amount) as total FROM fees`, (err, paidFee) => {
                    const total = totalFee?.total || 0;
                    const paid = paidFee?.total || 0;
                    const pending = total - paid;
                    
                    res.json({
                        success: true,
                        stats: {
                            total_students: students?.total || 0,
                            total_teachers: teachers?.total || 0,
                            total_expected: total,
                            total_collected: paid,
                            total_pending: pending,
                            total_overdue: 0,
                            collection_percentage: total > 0 ? Math.round((paid / total) * 100) : 0,
                        }
                    });
                });
            });
        });
    });
});

app.get('/api/accountant/students', verifyToken, checkRole(['accountant']), (req, res) => {
    db.all(
        `SELECT s.*, u.name, u.email, u.phone, 
                f.total_amount, f.paid_amount, f.status as fee_status, f.due_date
         FROM students s 
         JOIN users u ON s.user_id = u.id 
         LEFT JOIN fees f ON s.id = f.student_id
         ORDER BY s.admission_no`,
        (err, students) => {
            res.json({ success: true, students: students || [] });
        }
    );
});

app.get('/api/accountant/student/:id', verifyToken, checkRole(['accountant']), (req, res) => {
    const { id } = req.params;
    
    db.get(
        `SELECT s.*, u.name, u.email, u.phone FROM students s 
         JOIN users u ON s.user_id = u.id WHERE s.id = ?`,
        [id],
        (err, student) => {
            if (!student) return res.status(404).json({ success: false });
            
            db.get(`SELECT * FROM fees WHERE student_id = ?`, [id], (err, fee) => {
                db.all(`SELECT * FROM payments WHERE student_id = ? ORDER BY payment_date DESC`, [id], (err, payments) => {
                    res.json({ success: true, student, fees: fee || {}, payments: payments || [] });
                });
            });
        }
    );
});

app.post('/api/accountant/student', verifyToken, checkRole(['accountant']), (req, res) => {
    const { name, phone, email, admission_no, class: className, section, roll_no, parent_name, parent_phone } = req.body;
    
    if (!name || !phone || !admission_no || !className) {
        return res.status(400).json({ success: false, message: 'Required fields missing' });
    }
    
    db.run(
        `INSERT INTO users (name, phone, email, role) VALUES (?, ?, ?, 'student')`,
        [name, phone, email || null],
        function(err) {
            if (err) return res.status(500).json({ success: false });
            const newUserId = this.lastID;
            
            db.run(
                `INSERT INTO students (user_id, admission_no, class, section, roll_no, parent_name, parent_phone) 
                 VALUES (?, ?, ?, ?, ?, ?, ?)`,
                [newUserId, admission_no, className, section || 'A', roll_no || '00', parent_name, parent_phone],
                function(err) {
                    if (err) return res.status(500).json({ success: false });
                    const newStudentId = this.lastID;
                    
                    db.get(`SELECT total_fee FROM fee_structure WHERE class = ?`, [className], (err, fs) => {
                        const totalFee = fs?.total_fee || 50000;
                        db.run(
                            `INSERT INTO fees (student_id, total_amount, paid_amount, due_date, status) 
                             VALUES (?, ?, 0, '2026-12-31', 'due')`,
                            [newStudentId, totalFee]
                        );
                    });
                    
                    res.json({ success: true, message: 'Student added', student_id: newStudentId });
                }
            );
        }
    );
});

app.put('/api/accountant/student/:id', verifyToken, checkRole(['accountant']), (req, res) => {
    const { id } = req.params;
    const { name, phone, email, class: className, section, roll_no, parent_name, parent_phone, address, reason } = req.body;
    
    db.get(`SELECT s.*, u.name, u.phone FROM students s JOIN users u ON s.user_id = u.id WHERE s.id = ?`, [id], (err, oldStudent) => {
        if (!oldStudent) return res.status(404).json({ success: false });
        
        if (name || phone || email) {
            db.run(
                `UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone), email = COALESCE(?, email) WHERE id = ?`,
                [name, phone, email, oldStudent.user_id]
            );
        }
        
        db.run(
            `UPDATE students SET class = COALESCE(?, class), section = COALESCE(?, section),
                roll_no = COALESCE(?, roll_no), parent_name = COALESCE(?, parent_name),
                parent_phone = COALESCE(?, parent_phone), address = COALESCE(?, address)
             WHERE id = ?`,
            [className, section, roll_no, parent_name, parent_phone, address, id],
            function(err) {
                if (err) return res.status(500).json({ success: false });
                res.json({ success: true, message: 'Student updated' });
            }
        );
    });
});

app.get('/api/accountant/teachers', verifyToken, checkRole(['accountant']), (req, res) => {
    db.all(
        `SELECT t.*, u.name, u.email, u.phone 
         FROM teachers t JOIN users u ON t.user_id = u.id ORDER BY t.staff_code`,
        (err, teachers) => {
            res.json({ success: true, teachers: teachers || [] });
        }
    );
});

app.get('/api/accountant/teacher/:id', verifyToken, checkRole(['accountant']), (req, res) => {
    const { id } = req.params;
    db.get(
        `SELECT t.*, u.name, u.email, u.phone FROM teachers t 
         JOIN users u ON t.user_id = u.id WHERE t.id = ?`,
        [id],
        (err, teacher) => {
            if (!teacher) return res.status(404).json({ success: false });
            res.json({ success: true, teacher });
        }
    );
});

app.post('/api/accountant/teacher', verifyToken, checkRole(['accountant']), (req, res) => {
    const { name, phone, email, staff_code, subject, designation, is_class_incharge, incharge_class, incharge_section, salary } = req.body;
    
    if (!name || !phone || !staff_code) {
        return res.status(400).json({ success: false, message: 'Required fields missing' });
    }
    
    db.run(
        `INSERT INTO users (name, phone, email, role) VALUES (?, ?, ?, 'teacher')`,
        [name, phone, email || null],
        function(err) {
            if (err) return res.status(500).json({ success: false });
            const newUserId = this.lastID;
            
            db.run(
                `INSERT INTO teachers (user_id, staff_code, designation, subject, is_class_incharge, incharge_class, incharge_section, salary) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                [newUserId, staff_code, designation || 'Teacher', subject || 'General', 
                 is_class_incharge ? 1 : 0, incharge_class || null, incharge_section || null, salary || 0],
                function(err) {
                    if (err) return res.status(500).json({ success: false });
                    res.json({ success: true, message: 'Teacher added', teacher_id: this.lastID });
                }
            );
        }
    );
});

app.put('/api/accountant/teacher/:id', verifyToken, checkRole(['accountant']), (req, res) => {
    const { id } = req.params;
    const { name, phone, email, subject, designation, is_class_incharge, incharge_class, incharge_section, salary, reason } = req.body;
    
    db.get(`SELECT * FROM teachers WHERE id = ?`, [id], (err, oldTeacher) => {
        if (!oldTeacher) return res.status(404).json({ success: false });
        
        if (name || phone || email) {
            db.run(
                `UPDATE users SET name = COALESCE(?, name), phone = COALESCE(?, phone), email = COALESCE(?, email) WHERE id = ?`,
                [name, phone, email, oldTeacher.user_id]
            );
        }
        
        db.run(
            `UPDATE teachers SET subject = COALESCE(?, subject), designation = COALESCE(?, designation),
                is_class_incharge = COALESCE(?, is_class_incharge), incharge_class = ?,
                incharge_section = ?, salary = COALESCE(?, salary)
             WHERE id = ?`,
            [subject, designation, is_class_incharge ? 1 : 0, 
             is_class_incharge ? incharge_class : null, is_class_incharge ? incharge_section : null,
             salary, id],
            function(err) {
                if (err) return res.status(500).json({ success: false });
                res.json({ success: true, message: 'Teacher updated' });
            }
        );
    });
});

app.post('/api/accountant/payment', verifyToken, checkRole(['accountant']), (req, res) => {
    const { student_id, amount, method, transaction_id, notes } = req.body;
    const studentId = parseInt(student_id);
    
    if (!studentId || !amount || amount <= 0) {
        return res.status(400).json({ success: false, message: 'Invalid payment details' });
    }
    
    db.get(`SELECT * FROM fees WHERE student_id = ?`, [studentId], (err, fee) => {
        if (!fee) return res.status(404).json({ success: false, message: 'Fee record not found' });
        
        const newPaidAmount = fee.paid_amount + parseFloat(amount);
        const totalAmount = fee.total_amount;
        let newStatus = 'partially_paid';
        
        if (newPaidAmount >= totalAmount) newStatus = 'paid';
        else if (newPaidAmount === 0) newStatus = 'due';
        
        db.run(
            `UPDATE fees SET paid_amount = ?, status = ?, last_updated = CURRENT_TIMESTAMP WHERE student_id = ?`,
            [newPaidAmount, newStatus, studentId],
            function(err) {
                if (err) return res.status(500).json({ success: false });
                
                const receiptNo = 'RCP' + Date.now().toString().slice(-6);
                
                db.run(
                    `INSERT INTO payments (student_id, amount, method, transaction_id, receipt_number, notes, recorded_by) 
                     VALUES (?, ?, ?, ?, ?, ?, ?)`,
                    [studentId, amount, method || 'Cash', transaction_id || null, receiptNo, notes || null, req.user.userId],
                    function(err) {
                        if (err) return res.status(500).json({ success: false });
                        
                        res.json({
                            success: true,
                            message: 'Payment recorded',
                            payment_id: this.lastID,
                            receipt_number: receiptNo,
                            new_paid: newPaidAmount,
                            new_due: totalAmount - newPaidAmount,
                            status: newStatus
                        });
                    }
                );
            }
        );
    });
});

app.get('/api/accountant/pending-dues', verifyToken, checkRole(['accountant']), (req, res) => {
    db.all(
        `SELECT s.id, s.admission_no, s.class, s.section, u.name, u.phone,
                f.total_amount, f.paid_amount, f.due_date, f.status,
                (f.total_amount - f.paid_amount) as due_amount
         FROM students s 
         JOIN users u ON s.user_id = u.id 
         JOIN fees f ON s.id = f.student_id
         WHERE f.paid_amount < f.total_amount
         ORDER BY due_amount DESC`,
        (err, dues) => {
            res.json({ success: true, pending: dues || [] });
        }
    );
});

app.get('/api/accountant/fee-structure', verifyToken, checkRole(['accountant']), (req, res) => {
    db.all(`SELECT * FROM fee_structure ORDER BY class`, (err, structures) => {
        res.json({ success: true, structures: structures || [] });
    });
});

app.put('/api/accountant/fee-structure', verifyToken, checkRole(['accountant']), (req, res) => {
    const { class: className, total_fee, term1, term2, term3 } = req.body;
    
    db.run(
        `INSERT OR REPLACE INTO fee_structure (class, total_fee, term1, term2, term3) 
         VALUES (?, ?, ?, ?, ?)`,
        [className, total_fee, term1, term2, term3],
        function(err) {
            if (err) return res.status(500).json({ success: false });
            res.json({ success: true, message: 'Fee structure updated' });
        }
    );
});

app.get('/api/accountant/audit-logs', verifyToken, checkRole(['accountant']), (req, res) => {
    db.all(
        `SELECT al.*, u.name as user_name FROM audit_logs al 
         LEFT JOIN users u ON al.user_id = u.id 
         ORDER BY al.timestamp DESC LIMIT 50`,
        (err, logs) => {
            res.json({ success: true, logs: logs || [] });
        }
    );
});

app.post('/api/accountant/apply-leave', verifyToken, checkRole(['accountant']), (req, res) => {
    const { start_date, end_date, reason } = req.body;
    
    if (!start_date || !end_date || !reason) {
        return res.status(400).json({ success: false, message: 'All fields required' });
    }
    
    db.run(
        `INSERT INTO staff_leaves (user_id, role, start_date, end_date, reason, status) 
         VALUES (?, 'accountant', ?, ?, ?, 'pending')`,
        [req.user.userId, start_date, end_date, reason],
        function(err) {
            if (err) return res.status(500).json({ success: false });
            res.json({ success: true, message: 'Leave sent to Principal', leave_id: this.lastID });
        }
    );
});

app.get('/api/accountant/my-leaves', verifyToken, checkRole(['accountant']), (req, res) => {
    db.all(
        `SELECT * FROM staff_leaves WHERE user_id = ? AND role = 'accountant'
         ORDER BY created_at DESC`,
        [req.user.userId],
        (err, leaves) => {
            res.json({ success: true, leaves: leaves || [] });
        }
    );
});

// ========== START SERVER ============
app.listen(PORT, () => {
    console.log('\n✅ SGHPS Backend Running!');
    console.log(`📍 http://localhost:${PORT}`);
    console.log('\n📚 Homework APIs (Updated):');
    console.log(`   POST /api/teacher/homework (auto today)`);
    console.log(`   GET  /api/teacher/homework (today)`);
    console.log(`   GET  /api/teacher/homework-history`);
    console.log(`   GET  /api/students/homework (today)`);
    console.log(`   GET  /api/students/homework-history`);
    console.log('\n👨‍🎓 Test Credentials:');
    console.log(`   Student: SGHPS-2024-001 / 9876543210`);
    console.log(`   Teacher: TCH-001 / TCH-001`);
    console.log(`   Principal: PR-001 / PR-001`);
    console.log(`   Accountant: ACC-001 / ACC-001`);
    console.log('\n📱 Database: sghps.db\n');
});