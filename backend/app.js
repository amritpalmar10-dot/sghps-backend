const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5001;

// ============ DATABASE ============
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DATABASE_URL?.includes('render.com') 
        ? { rejectUnauthorized: false } 
        : false
});

pool.on('connect', () => console.log('✅ PostgreSQL connected'));
pool.on('error', (err) => console.error('❌ PG error:', err.message));

// ============ CREATE TABLES ============
async function initDatabase() {
    console.log('📦 Creating tables...');
    
    await pool.query(`
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name TEXT, email TEXT, phone TEXT, role TEXT
        );
        
        CREATE TABLE IF NOT EXISTS students (
            id SERIAL PRIMARY KEY,
            user_id INTEGER, admission_no TEXT UNIQUE, class TEXT, section TEXT,
            roll_no TEXT, parent_name TEXT, parent_phone TEXT, parent_email TEXT,
            address TEXT, dob TEXT, gender TEXT
        );
        
        CREATE TABLE IF NOT EXISTS teachers (
            id SERIAL PRIMARY KEY,
            user_id INTEGER, staff_code TEXT UNIQUE, designation TEXT,
            subject TEXT, is_class_incharge INTEGER DEFAULT 0,
            incharge_class TEXT, incharge_section TEXT, salary REAL DEFAULT 0
        );
        
        CREATE TABLE IF NOT EXISTS principals (
            id SERIAL PRIMARY KEY,
            user_id INTEGER, principal_code TEXT UNIQUE
        );
        
        CREATE TABLE IF NOT EXISTS accountants (
            id SERIAL PRIMARY KEY,
            user_id INTEGER, accountant_code TEXT UNIQUE
        );
        
        CREATE TABLE IF NOT EXISTS otp_requests (
            id SERIAL PRIMARY KEY,
            user_id INTEGER, otp TEXT, expires_at TEXT, used INTEGER DEFAULT 0
        );
        
        CREATE TABLE IF NOT EXISTS leaves (
            id SERIAL PRIMARY KEY,
            student_id INTEGER, start_date TEXT, end_date TEXT,
            reason TEXT, status TEXT DEFAULT 'pending', approved_by INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS staff_leaves (
            id SERIAL PRIMARY KEY,
            user_id INTEGER, role TEXT, start_date TEXT, end_date TEXT,
            reason TEXT, status TEXT DEFAULT 'pending', approved_by INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS fees (
            id SERIAL PRIMARY KEY,
            student_id INTEGER UNIQUE, total_amount REAL DEFAULT 0,
            paid_amount REAL DEFAULT 0, due_date TEXT, status TEXT DEFAULT 'due',
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS payments (
            id SERIAL PRIMARY KEY,
            student_id INTEGER, amount REAL, method TEXT,
            transaction_id TEXT, receipt_number TEXT, notes TEXT,
            recorded_by INTEGER, payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS fee_structure (
            id SERIAL PRIMARY KEY,
            class TEXT UNIQUE, total_fee REAL, term1 REAL, term2 REAL, term3 REAL
        );

        CREATE TABLE IF NOT EXISTS audit_logs (
            id SERIAL PRIMARY KEY,
            user_id INTEGER, action TEXT, entity TEXT, entity_id INTEGER,
            field_changed TEXT, old_value TEXT, new_value TEXT, reason TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS attendance (
            id SERIAL PRIMARY KEY,
            student_id INTEGER,
            date TEXT,
            status TEXT CHECK(status IN ('present', 'absent', 'late')),
            teacher_id INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(student_id, date)
        );

        CREATE TABLE IF NOT EXISTS homework (
            id SERIAL PRIMARY KEY,
            teacher_id INTEGER,
            class TEXT,
            section TEXT,
            subject TEXT,
            title TEXT,
            description TEXT,
            homework_date TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS homework_submissions (
            id SERIAL PRIMARY KEY,
            homework_id INTEGER,
            student_id INTEGER,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            status TEXT DEFAULT 'submitted',
            UNIQUE(homework_id, student_id)
        );

        CREATE TABLE IF NOT EXISTS events (
            id SERIAL PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            event_date TEXT NOT NULL,
            event_time TEXT,
            location TEXT,
            type TEXT DEFAULT 'event',
            priority TEXT DEFAULT 'normal',
            created_by INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS exams (
            id SERIAL PRIMARY KEY,
            name TEXT, subject TEXT, class TEXT, section TEXT,
            exam_date TEXT, start_time TEXT, duration INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    `);
    
    console.log('✅ All tables created');
    
    // ============ INSERT TEST DATA ============
    const result = await pool.query('SELECT COUNT(*) as count FROM users');
    if (parseInt(result.rows[0].count) === 0) {
        console.log('📥 Inserting test data...');
        
        await pool.query(`
            INSERT INTO users (name, email, phone, role) VALUES 
                ('Manavjot Singh', 'manavjot@test.com', '9876543210', 'student'),
                ('Navdeep Singh', 'navdeep@test.com', '9876543211', 'teacher'),
                ('Jaskaran Singh', 'jaskaran@test.com', '9876543212', 'principal'),
                ('Amritpal Singh', 'amritpal@test.com', '9876543213', 'accountant')
        `);
        
        await pool.query(`
            INSERT INTO students (user_id, admission_no, class, section, roll_no, parent_name, parent_phone) VALUES 
                (1, 'SGHPS-2024-001', 'XII', 'A', '01', 'Gurpreet Singh', '9876543214')
        `);
        
        await pool.query(`
            INSERT INTO teachers (user_id, staff_code, designation, subject, is_class_incharge, incharge_class, incharge_section, salary) 
            VALUES (2, 'TCH-001', 'Senior Teacher', 'Mathematics', 1, 'XII', 'A', 50000)
        `);
        
        await pool.query(`INSERT INTO principals (user_id, principal_code) VALUES (3, 'PR-001')`);
        await pool.query(`INSERT INTO accountants (user_id, accountant_code) VALUES (4, 'ACC-001')`);
        
        await pool.query(`
            INSERT INTO fees (student_id, total_amount, paid_amount, due_date, status) 
            VALUES (1, 50000, 35000, '2026-12-31', 'partially_paid')
        `);
        
        await pool.query(`
            INSERT INTO payments (student_id, amount, method, receipt_number) VALUES 
                (1, 20000, 'Online', 'RCP001'), (1, 15000, 'Cash', 'RCP002')
        `);
        
        await pool.query(`
            INSERT INTO fee_structure (class, total_fee, term1, term2, term3) VALUES 
                ('XII', 50000, 20000, 15000, 15000),
                ('XI', 45000, 18000, 15000, 12000),
                ('X', 40000, 15000, 13000, 12000)
        `);
        
        // Sample attendance (last 30 days)
        for (let i = 0; i < 30; i++) {
            const date = new Date();
            date.setDate(date.getDate() - i);
            const dateStr = date.toISOString().split('T')[0];
            const status = i % 7 === 0 ? 'absent' : (i % 11 === 0 ? 'late' : 'present');
            
            await pool.query(
                `INSERT INTO attendance (student_id, date, status, teacher_id) 
                 VALUES (1, $1, $2, 2) ON CONFLICT (student_id, date) DO NOTHING`,
                [dateStr, status]
            );
        }
        
        // Homework
        const today = new Date().toISOString().split('T')[0];
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = yesterday.toISOString().split('T')[0];
        const twoDaysAgo = new Date();
        twoDaysAgo.setDate(twoDaysAgo.getDate() - 2);
        const twoDaysAgoStr = twoDaysAgo.toISOString().split('T')[0];
        
        await pool.query(
            `INSERT INTO homework (teacher_id, class, section, subject, title, description, homework_date) VALUES 
                (2, 'XII', 'A', 'Mathematics', 'Chapter 5: Calculus', 'Solve exercises 1-10 from NCERT', $1),
                (2, 'XII', 'A', 'Physics', 'Laws of Motion', 'Complete numerical problems', $1)`,
            [today]
        );
        
        await pool.query(
            `INSERT INTO homework (teacher_id, class, section, subject, title, description, homework_date) VALUES 
                (2, 'XII', 'A', 'Mathematics', 'Chapter 4: Integrals', 'Practice integration problems', $1),
                (2, 'XII', 'A', 'Chemistry', 'Chemical Bonding', 'Revise notes', $1)`,
            [yesterdayStr]
        );
        
        await pool.query(
            `INSERT INTO homework (teacher_id, class, section, subject, title, description, homework_date) VALUES 
                (2, 'XII', 'A', 'English', 'Essay Writing', 'Write 500 words on "My School"', $1)`,
            [twoDaysAgoStr]
        );
        
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        
        await pool.query(
            `INSERT INTO events (title, description, event_date, type) VALUES 
                ('Annual Sports Day', 'Annual sports competition', $1, 'event'),
                ('Parent Teacher Meeting', 'PTM for all classes', $1, 'ptm')`,
            [tomorrow.toISOString().split('T')[0]]
        );
        
        console.log('✅ Test data inserted');
    }
}

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

app.post('/api/auth/student/login', async (req, res) => {
    const { admission_no, phone } = req.body;
    
    try {
        const result = await pool.query(
            `SELECT u.id as user_id, u.name FROM students s 
             JOIN users u ON s.user_id = u.id 
             WHERE s.admission_no = $1 AND u.phone = $2`,
            [admission_no, phone]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Student not found' });
        }
        
        const student = result.rows[0];
        const otp = Math.floor(100000 + Math.random() * 900000);
        const expires = new Date(Date.now() + 5 * 60000).toISOString();
        
        await pool.query(
            `INSERT INTO otp_requests (user_id, otp, expires_at) VALUES ($1, $2, $3)`,
            [student.user_id, otp.toString(), expires]
        );
        
        console.log(`📱 OTP for ${student.name}: ${otp}`);
        res.json({ success: true, message: 'OTP sent', userId: student.user_id, testOtp: otp });
    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

app.post('/api/auth/verify-otp', async (req, res) => {
    const { userId, otp } = req.body;
    
    if (!userId || !otp) {
        return res.status(400).json({ success: false, message: 'User ID and OTP required' });
    }
    
    try {
        const result = await pool.query(
            `SELECT * FROM otp_requests 
             WHERE user_id = $1 AND otp = $2 AND used = 0
             ORDER BY id DESC LIMIT 1`,
            [userId, otp.toString()]
        );
        
        if (result.rows.length === 0) {
            return res.status(401).json({ success: false, message: 'Invalid OTP' });
        }
        
        const record = result.rows[0];
        await pool.query(`UPDATE otp_requests SET used = 1 WHERE id = $1`, [record.id]);
        
        const userResult = await pool.query(
            `SELECT id, name, email, phone, role FROM users WHERE id = $1`,
            [userId]
        );
        
        const user = userResult.rows[0];
        const token = jwt.sign(
            { userId: user.id, role: user.role },
            process.env.JWT_SECRET || 'sghps-secret-key',
            { expiresIn: '7d' }
        );
        
        res.json({ success: true, token, user });
    } catch (err) {
        console.error('OTP verify error:', err);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

app.post('/api/auth/teacher/login', async (req, res) => {
    const { staff_code, password } = req.body;
    
    try {
        const result = await pool.query(
            `SELECT t.*, u.id as user_id, u.name, u.email, u.phone, u.role 
             FROM teachers t JOIN users u ON t.user_id = u.id 
             WHERE t.staff_code = $1`,
            [staff_code]
        );
        
        if (result.rows.length === 0 || password !== staff_code) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }
        
        const teacher = result.rows[0];
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
    } catch (err) {
        console.error('Teacher login error:', err);
        res.status(500).json({ success: false, message: 'Server error' });
    }
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

app.get('/api/students/profile', verifyToken, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT s.*, u.name, u.email, u.phone FROM students s 
             JOIN users u ON s.user_id = u.id WHERE u.id = $1`,
            [req.user.userId]
        );
        res.json({ success: true, student: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/students/attendance', verifyToken, async (req, res) => {
    try {
        const sResult = await pool.query(`SELECT id FROM students WHERE user_id = $1`, [req.user.userId]);
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const result = await pool.query(
            `SELECT date, status FROM attendance 
             WHERE student_id = $1 
             ORDER BY date DESC LIMIT 30`,
            [sResult.rows[0].id]
        );
        
        const records = result.rows;
        const total = records.length;
        const present = records.filter(r => r.status === 'present').length;
        const percentage = total > 0 ? Math.round((present / total) * 100) : 0;
        
        res.json({ success: true, attendance: records, percentage, total, present });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/students/attendance-calendar', verifyToken, async (req, res) => {
    const { month, year } = req.query;
    const currentDate = new Date();
    const m = month || (currentDate.getMonth() + 1);
    const y = year || currentDate.getFullYear();
    
    const startDate = `${y}-${m.toString().padStart(2, '0')}-01`;
    const endDate = `${y}-${m.toString().padStart(2, '0')}-31`;
    
    try {
        const sResult = await pool.query(`SELECT id FROM students WHERE user_id = $1`, [req.user.userId]);
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const result = await pool.query(
            `SELECT date, status FROM attendance 
             WHERE student_id = $1 AND date BETWEEN $2 AND $3
             ORDER BY date`,
            [sResult.rows[0].id, startDate, endDate]
        );
        
        const records = result.rows;
        const total = records.length;
        const present = records.filter(r => r.status === 'present').length;
        const absent = records.filter(r => r.status === 'absent').length;
        const late = records.filter(r => r.status === 'late').length;
        const percentage = total > 0 ? Math.round((present / total) * 100) : 0;
        
        res.json({
            success: true,
            month: parseInt(m), year: parseInt(y),
            records,
            stats: { total, present, absent, late, percentage }
        });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/students/fees', verifyToken, async (req, res) => {
    try {
        const sResult = await pool.query(`SELECT id FROM students WHERE user_id = $1`, [req.user.userId]);
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const studentId = sResult.rows[0].id;
        const feeResult = await pool.query(`SELECT * FROM fees WHERE student_id = $1`, [studentId]);
        const payResult = await pool.query(
            `SELECT * FROM payments WHERE student_id = $1 ORDER BY payment_date DESC`,
            [studentId]
        );
        
        const fee = feeResult.rows[0];
        const payments = payResult.rows;
        
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
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/students/homework', verifyToken, async (req, res) => {
    try {
        const sResult = await pool.query(
            `SELECT class, section FROM students WHERE user_id = $1`,
            [req.user.userId]
        );
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const student = sResult.rows[0];
        const today = new Date().toISOString().split('T')[0];
        
        const result = await pool.query(
            `SELECT h.*, u.name as teacher_name,
                    (SELECT COUNT(*) FROM homework_submissions 
                     WHERE homework_id = h.id AND student_id = $1) as is_submitted
             FROM homework h
             JOIN users u ON h.teacher_id = u.id
             WHERE h.class = $2 AND h.section = $3
             AND h.homework_date = $4
             ORDER BY h.created_at DESC`,
            [req.user.userId, student.class, student.section, today]
        );
        
        res.json({ success: true, homework: result.rows || [], date: today });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/students/homework-history', verifyToken, async (req, res) => {
    try {
        const sResult = await pool.query(
            `SELECT class, section FROM students WHERE user_id = $1`,
            [req.user.userId]
        );
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const student = sResult.rows[0];
        const today = new Date().toISOString().split('T')[0];
        
        const result = await pool.query(
            `SELECT h.*, u.name as teacher_name,
                    (SELECT COUNT(*) FROM homework_submissions 
                     WHERE homework_id = h.id AND student_id = $1) as is_submitted
             FROM homework h
             JOIN users u ON h.teacher_id = u.id
             WHERE h.class = $2 AND h.section = $3
             AND h.homework_date < $4
             ORDER BY h.homework_date DESC, h.created_at DESC
             LIMIT 100`,
            [req.user.userId, student.class, student.section, today]
        );
        
        res.json({ success: true, homework: result.rows || [], count: result.rows.length });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.post('/api/students/homework/:homeworkId/submit', verifyToken, async (req, res) => {
    const { homeworkId } = req.params;
    
    try {
        const sResult = await pool.query(`SELECT id FROM students WHERE user_id = $1`, [req.user.userId]);
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        
        await pool.query(
            `INSERT INTO homework_submissions (homework_id, student_id, status) 
             VALUES ($1, $2, 'submitted')
             ON CONFLICT (homework_id, student_id) DO NOTHING`,
            [homeworkId, sResult.rows[0].id]
        );
        
        res.json({ success: true, message: 'Homework submitted!' });
    } catch (err) {
        res.status(500).json({ success: false });
    }
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

app.get('/api/students/events', async (req, res) => {
    try {
        const result = await pool.query(`SELECT * FROM events ORDER BY event_date DESC`);
        res.json({ success: true, events: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.post('/api/students/leave', verifyToken, async (req, res) => {
    const { start_date, end_date, reason } = req.body;
    
    if (!start_date || !end_date || !reason) {
        return res.status(400).json({ success: false, message: 'All fields required' });
    }
    
    try {
        const sResult = await pool.query(`SELECT id FROM students WHERE user_id = $1`, [req.user.userId]);
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const result = await pool.query(
            `INSERT INTO leaves (student_id, start_date, end_date, reason, status) 
             VALUES ($1, $2, $3, $4, 'pending') RETURNING id`,
            [sResult.rows[0].id, start_date, end_date, reason]
        );
        
        res.json({ success: true, message: 'Leave applied', leave_id: result.rows[0].id });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/students/my-leaves', verifyToken, async (req, res) => {
    try {
        const sResult = await pool.query(`SELECT id FROM students WHERE user_id = $1`, [req.user.userId]);
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const result = await pool.query(
            `SELECT * FROM leaves WHERE student_id = $1 ORDER BY created_at DESC`,
            [sResult.rows[0].id]
        );
        
        res.json({ success: true, leaves: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

// ============================================
// ========== TEACHER APIs ==========
// ============================================

app.get('/api/teacher/check-incharge', verifyToken, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT t.*, u.name FROM teachers t 
             JOIN users u ON t.user_id = u.id WHERE u.id = $1`,
            [req.user.userId]
        );
        
        if (result.rows.length === 0) return res.status(404).json({ success: false });
        const teacher = result.rows[0];
        
        res.json({
            success: true,
            is_class_incharge: teacher.is_class_incharge === 1,
            incharge_class: teacher.incharge_class || '',
            incharge_section: teacher.incharge_section || '',
            teacher_name: teacher.name
        });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/teacher/pending-leaves', verifyToken, checkRole(['teacher']), async (req, res) => {
    try {
        const tResult = await pool.query(
            `SELECT t.* FROM teachers t WHERE t.user_id = $1`,
            [req.user.userId]
        );
        
        if (tResult.rows.length === 0 || tResult.rows[0].is_class_incharge !== 1) {
            return res.status(403).json({ success: false, message: 'Only class incharge' });
        }
        
        const teacher = tResult.rows[0];
        const result = await pool.query(
            `SELECT l.*, s.admission_no, u.name as student_name, s.class, s.section 
             FROM leaves l 
             JOIN students s ON l.student_id = s.id 
             JOIN users u ON s.user_id = u.id 
             WHERE s.class = $1 AND s.section = $2
             ORDER BY l.created_at DESC`,
            [teacher.incharge_class, teacher.incharge_section]
        );
        
        res.json({ success: true, leaves: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.put('/api/teacher/leave/:leaveId', verifyToken, checkRole(['teacher']), async (req, res) => {
    const { leaveId } = req.params;
    const { status } = req.body;
    
    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ success: false, message: 'Invalid status' });
    }
    
    try {
        await pool.query(
            `UPDATE leaves SET status = $1, approved_by = $2 WHERE id = $3`,
            [status, req.user.userId, leaveId]
        );
        res.json({ success: true, message: `Leave ${status}` });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.post('/api/teacher/mark-attendance', verifyToken, checkRole(['teacher']), async (req, res) => {
    const { class: className, section, date, attendance } = req.body;
    const teacherId = req.user.userId;
    
    if (!className || !section || !date || !attendance) {
        return res.status(400).json({ success: false, message: 'All fields required' });
    }
    
    try {
        const tResult = await pool.query(`SELECT * FROM teachers WHERE user_id = $1`, [teacherId]);
        if (tResult.rows.length === 0 || tResult.rows[0].is_class_incharge !== 1) {
            return res.status(403).json({ success: false, message: 'Only class incharge can mark attendance' });
        }
        
        await pool.query(
            `DELETE FROM attendance WHERE date = $1 AND student_id IN 
             (SELECT id FROM students WHERE class = $2 AND section = $3)`,
            [date, className, section]
        );
        
        if (attendance.length === 0) {
            return res.json({ success: true, message: 'No records', count: 0 });
        }
        
        for (const record of attendance) {
            await pool.query(
                `INSERT INTO attendance (student_id, date, status, teacher_id) 
                 VALUES ($1, $2, $3, $4)`,
                [record.student_id, date, record.status, teacherId]
            );
        }
        
        res.json({
            success: true,
            message: 'Attendance marked',
            date, count: attendance.length
        });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

// ============================================
// ========== EVENTS APIs ==========
// ============================================

app.post('/api/events/create', verifyToken, checkRole(['principal', 'teacher']), async (req, res) => {
    const { title, description, event_date, event_time, location, type, priority } = req.body;
    const userId = req.user.userId;
    
    if (!title || !event_date) {
        return res.status(400).json({ success: false, message: 'Title and date required' });
    }
    
    try {
        const result = await pool.query(
            `INSERT INTO events (title, description, event_date, event_time, location, type, priority, created_by) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`,
            [title, description || '', event_date, event_time || '', location || '', 
             type || 'event', priority || 'normal', userId]
        );
        
        res.json({
            success: true,
            message: 'Event created successfully',
            event_id: result.rows[0].id
        });
    } catch (err) {
        res.status(500).json({ success: false, message: 'Error' });
    }
});

app.get('/api/events', verifyToken, async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT e.*, u.name as created_by_name, u.role as created_by_role
             FROM events e
             LEFT JOIN users u ON e.created_by = u.id
             ORDER BY e.event_date DESC`
        );
        res.json({ success: true, events: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/events/upcoming', verifyToken, async (req, res) => {
    const today = new Date().toISOString().split('T')[0];
    
    try {
        const result = await pool.query(
            `SELECT e.*, u.name as created_by_name, u.role as created_by_role
             FROM events e
             LEFT JOIN users u ON e.created_by = u.id
             WHERE e.event_date >= $1
             ORDER BY e.event_date ASC
             LIMIT 10`,
            [today]
        );
        res.json({ success: true, events: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/events/calendar', verifyToken, async (req, res) => {
    const { month, year } = req.query;
    const currentDate = new Date();
    const m = month || (currentDate.getMonth() + 1);
    const y = year || currentDate.getFullYear();
    
    const startDate = `${y}-${m.toString().padStart(2, '0')}-01`;
    const endDate = `${y}-${m.toString().padStart(2, '0')}-31`;
    
    try {
        const result = await pool.query(
            `SELECT e.*, u.name as created_by_name
             FROM events e
             LEFT JOIN users u ON e.created_by = u.id
             WHERE e.event_date BETWEEN $1 AND $2
             ORDER BY e.event_date`,
            [startDate, endDate]
        );
        res.json({ success: true, events: result.rows || [], month: parseInt(m), year: parseInt(y) });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.put('/api/events/:eventId', verifyToken, checkRole(['principal', 'teacher']), async (req, res) => {
    const { eventId } = req.params;
    const { title, description, event_date, event_time, location, type, priority } = req.body;
    const userId = req.user.userId;
    const userRole = req.user.role;
    
    try {
        const eResult = await pool.query(`SELECT * FROM events WHERE id = $1`, [eventId]);
        if (eResult.rows.length === 0) return res.status(404).json({ success: false, message: 'Event not found' });
        
        const event = eResult.rows[0];
        if (userRole !== 'principal' && event.created_by !== userId) {
            return res.status(403).json({ success: false, message: 'Not authorized' });
        }
        
        await pool.query(
            `UPDATE events SET 
                title = COALESCE($1, title),
                description = COALESCE($2, description),
                event_date = COALESCE($3, event_date),
                event_time = COALESCE($4, event_time),
                location = COALESCE($5, location),
                type = COALESCE($6, type),
                priority = COALESCE($7, priority)
             WHERE id = $8`,
            [title, description, event_date, event_time, location, type, priority, eventId]
        );
        
        res.json({ success: true, message: 'Event updated' });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.delete('/api/events/:eventId', verifyToken, checkRole(['principal', 'teacher']), async (req, res) => {
    const { eventId } = req.params;
    const userId = req.user.userId;
    const userRole = req.user.role;
    
    try {
        const eResult = await pool.query(`SELECT * FROM events WHERE id = $1`, [eventId]);
        if (eResult.rows.length === 0) return res.status(404).json({ success: false, message: 'Event not found' });
        
        const event = eResult.rows[0];
        if (userRole !== 'principal' && event.created_by !== userId) {
            return res.status(403).json({ success: false, message: 'Not authorized' });
        }
        
        await pool.query(`DELETE FROM events WHERE id = $1`, [eventId]);
        res.json({ success: true, message: 'Event deleted' });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/attendance/by-date', verifyToken, async (req, res) => {
    const { date, class: className, section } = req.query;
    
    if (!date) return res.status(400).json({ success: false, message: 'Date required' });
    
    let query = `
        SELECT a.*, s.admission_no, s.roll_no, u.name as student_name,
               s.class, s.section
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        JOIN users u ON s.user_id = u.id
        WHERE a.date = $1
    `;
    const params = [date];
    
    if (className) { query += ` AND s.class = $${params.length + 1}`; params.push(className); }
    if (section) { query += ` AND s.section = $${params.length + 1}`; params.push(section); }
    
    query += ` ORDER BY s.roll_no`;
    
    try {
        const result = await pool.query(query, params);
        res.json({ success: true, attendance: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/attendance/range', verifyToken, async (req, res) => {
    const { start, end, class: className, section } = req.query;
    
    if (!start || !end) return res.status(400).json({ success: false, message: 'Dates required' });
    
    let query = `
        SELECT a.*, s.admission_no, s.roll_no, u.name as student_name
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        JOIN users u ON s.user_id = u.id
        WHERE a.date BETWEEN $1 AND $2
    `;
    const params = [start, end];
    
    if (className) { query += ` AND s.class = $${params.length + 1}`; params.push(className); }
    if (section) { query += ` AND s.section = $${params.length + 1}`; params.push(section); }
    
    query += ` ORDER BY a.date DESC`;
    
    try {
        const result = await pool.query(query, params);
        res.json({ success: true, attendance: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/attendance/class-stats', verifyToken, async (req, res) => {
    const { class: className, section, month, year } = req.query;
    
    if (!className || !section) {
        return res.status(400).json({ success: false, message: 'Class and section required' });
    }
    
    const currentDate = new Date();
    const m = month || (currentDate.getMonth() + 1);
    const y = year || currentDate.getFullYear();
    
    const startDate = `${y}-${m.toString().padStart(2, '0')}-01`;
    const endDate = `${y}-${m.toString().padStart(2, '0')}-31`;
    
    try {
        const result = await pool.query(
            `SELECT date, 
                    COUNT(*) as total,
                    SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as present,
                    SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END) as absent,
                    SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END) as late
             FROM attendance 
             WHERE student_id IN (SELECT id FROM students WHERE class = $1 AND section = $2)
             AND date BETWEEN $3 AND $4
             GROUP BY date
             ORDER BY date`,
            [className, section, startDate, endDate]
        );
        res.json({ success: true, stats: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.post('/api/teacher/homework', verifyToken, checkRole(['teacher']), async (req, res) => {
    const { class: className, section, subject, title, description } = req.body;
    const teacherId = req.user.userId;
    
    if (!className || !section || !subject || !title) {
        return res.status(400).json({ success: false, message: 'Class, section, subject and title required' });
    }
    
    const today = new Date().toISOString().split('T')[0];
    
    try {
        const result = await pool.query(
            `INSERT INTO homework (teacher_id, class, section, subject, title, description, homework_date) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
            [teacherId, className, section, subject, title, description || '', today]
        );
        
        res.json({
            success: true,
            message: 'Homework created for today',
            homework_id: result.rows[0].id,
            date: today,
            expires: 'Midnight 00:00'
        });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/teacher/homework', verifyToken, checkRole(['teacher']), async (req, res) => {
    try {
        const tResult = await pool.query(`SELECT * FROM teachers WHERE user_id = $1`, [req.user.userId]);
        if (tResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const teacher = tResult.rows[0];
        const today = new Date().toISOString().split('T')[0];
        
        const result = await pool.query(
            `SELECT h.*,
                    (SELECT COUNT(*) FROM homework_submissions 
                     WHERE homework_id = h.id) as submissions_count
             FROM homework h
             WHERE h.teacher_id = $1
             AND h.homework_date = $2
             ORDER BY h.created_at DESC`,
            [teacher.id, today]
        );
        
        res.json({ success: true, homework: result.rows || [], date: today });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/teacher/homework-history', verifyToken, checkRole(['teacher']), async (req, res) => {
    try {
        const tResult = await pool.query(`SELECT * FROM teachers WHERE user_id = $1`, [req.user.userId]);
        if (tResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const teacher = tResult.rows[0];
        const today = new Date().toISOString().split('T')[0];
        
        const result = await pool.query(
            `SELECT h.*,
                    (SELECT COUNT(*) FROM homework_submissions 
                     WHERE homework_id = h.id) as submissions_count
             FROM homework h
             WHERE h.teacher_id = $1
             AND h.homework_date < $2
             ORDER BY h.homework_date DESC
             LIMIT 100`,
            [teacher.id, today]
        );
        
        res.json({ success: true, homework: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/teacher/homework/:homeworkId/submissions', verifyToken, checkRole(['teacher']), async (req, res) => {
    const { homeworkId } = req.params;
    
    try {
        const result = await pool.query(
            `SELECT hs.*, u.name as student_name, s.admission_no, s.roll_no
             FROM homework_submissions hs
             JOIN students s ON hs.student_id = s.id
             JOIN users u ON s.user_id = u.id
             WHERE hs.homework_id = $1
             ORDER BY s.roll_no`,
            [homeworkId]
        );
        res.json({ success: true, submissions: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.post('/api/teacher/apply-leave', verifyToken, checkRole(['teacher']), async (req, res) => {
    const { start_date, end_date, reason } = req.body;
    
    if (!start_date || !end_date || !reason) {
        return res.status(400).json({ success: false, message: 'All fields required' });
    }
    
    try {
        const result = await pool.query(
            `INSERT INTO staff_leaves (user_id, role, start_date, end_date, reason, status) 
             VALUES ($1, 'teacher', $2, $3, $4, 'pending') RETURNING id`,
            [req.user.userId, start_date, end_date, reason]
        );
        res.json({ success: true, message: 'Leave request sent to Principal', leave_id: result.rows[0].id });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/teacher/my-leaves', verifyToken, checkRole(['teacher']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT * FROM staff_leaves 
             WHERE user_id = $1 AND role = 'teacher'
             ORDER BY created_at DESC`,
            [req.user.userId]
        );
        res.json({ success: true, leaves: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

// ============================================
// ========== PRINCIPAL APIs ============
// ============================================

app.get('/api/principal/stats', verifyToken, checkRole(['principal']), async (req, res) => {
    try {
        const students = await pool.query(`SELECT COUNT(*) as total FROM students`);
        const teachers = await pool.query(`SELECT COUNT(*) as total FROM teachers`);
        const classes = await pool.query(`SELECT COUNT(DISTINCT class) as total FROM students`);
        const staffLeaves = await pool.query(`SELECT COUNT(*) as total FROM staff_leaves WHERE status = 'pending'`);
        const studentLeaves = await pool.query(`SELECT COUNT(*) as total FROM leaves WHERE status = 'pending'`);
        
        res.json({
            success: true,
            stats: {
                total_students: parseInt(students.rows[0].total) || 0,
                total_teachers: parseInt(teachers.rows[0].total) || 0,
                total_classes: parseInt(classes.rows[0].total) || 0,
                pending_teacher_leaves: parseInt(staffLeaves.rows[0].total) || 0,
                pending_student_leaves: parseInt(studentLeaves.rows[0].total) || 0,
                today_present: 39,
                today_absent: 3,
                attendance_percentage: 92.8,
            }
        });
    } catch (err) {
        res.status(500).json({ success: false });
    }
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

app.get('/api/principal/teachers', verifyToken, checkRole(['principal']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT t.*, u.name, u.email, u.phone FROM teachers t 
             JOIN users u ON t.user_id = u.id`
        );
        
        const formatted = result.rows.map(t => ({
            id: t.id, name: t.name, staff_code: t.staff_code,
            subject: t.subject || 'Mathematics',
            designation: t.designation || 'Teacher',
            is_class_incharge: t.is_class_incharge === 1,
            incharge_class: t.incharge_class || '',
            incharge_section: t.incharge_section || '',
            classes_count: 5, students_count: 120,
        }));
        
        res.json({ success: true, teachers: formatted });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/principal/staff-leaves', verifyToken, checkRole(['principal']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT sl.*, u.name as staff_name, u.phone, u.role
             FROM staff_leaves sl 
             JOIN users u ON sl.user_id = u.id 
             ORDER BY sl.created_at DESC`
        );
        res.json({ success: true, leaves: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.put('/api/principal/staff-leave/:leaveId', verifyToken, checkRole(['principal']), async (req, res) => {
    const { leaveId } = req.params;
    const { status } = req.body;
    
    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ success: false, message: 'Invalid status' });
    }
    
    try {
        await pool.query(
            `UPDATE staff_leaves SET status = $1, approved_by = $2 WHERE id = $3`,
            [status, req.user.userId, leaveId]
        );
        res.json({ success: true, message: `Leave ${status}` });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/principal/teacher-leaves', verifyToken, checkRole(['principal']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT l.*, s.admission_no, u.name as student_name, s.class, s.section 
             FROM leaves l 
             JOIN students s ON l.student_id = s.id 
             JOIN users u ON s.user_id = u.id 
             ORDER BY l.created_at DESC`
        );
        res.json({ success: true, leaves: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.put('/api/principal/teacher-leave/:leaveId', verifyToken, checkRole(['principal']), async (req, res) => {
    const { leaveId } = req.params;
    const { status } = req.body;
    
    if (!['approved', 'rejected'].includes(status)) {
        return res.status(400).json({ success: false, message: 'Invalid status' });
    }
    
    try {
        await pool.query(
            `UPDATE leaves SET status = $1, approved_by = $2 WHERE id = $3`,
            [status, req.user.userId, leaveId]
        );
        res.json({ success: true, message: `Leave ${status}` });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

// ============================================
// ========== ACCOUNTANT APIs ============
// ============================================

app.get('/api/accountant/stats', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const students = await pool.query(`SELECT COUNT(*) as total FROM students`);
        const teachers = await pool.query(`SELECT COUNT(*) as total FROM teachers`);
        const totalFee = await pool.query(`SELECT SUM(total_amount) as total FROM fees`);
        const paidFee = await pool.query(`SELECT SUM(paid_amount) as total FROM fees`);
        
        const total = parseFloat(totalFee.rows[0].total) || 0;
        const paid = parseFloat(paidFee.rows[0].total) || 0;
        const pending = total - paid;
        
        res.json({
            success: true,
            stats: {
                total_students: parseInt(students.rows[0].total) || 0,
                total_teachers: parseInt(teachers.rows[0].total) || 0,
                total_expected: total,
                total_collected: paid,
                total_pending: pending,
                total_overdue: 0,
                collection_percentage: total > 0 ? Math.round((paid / total) * 100) : 0,
            }
        });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/accountant/students', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT s.*, u.name, u.email, u.phone, 
                    f.total_amount, f.paid_amount, f.status as fee_status, f.due_date
             FROM students s 
             JOIN users u ON s.user_id = u.id 
             LEFT JOIN fees f ON s.id = f.student_id
             ORDER BY s.admission_no`
        );
        res.json({ success: true, students: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/accountant/student/:id', verifyToken, checkRole(['accountant']), async (req, res) => {
    const { id } = req.params;
    
    try {
        const sResult = await pool.query(
            `SELECT s.*, u.name, u.email, u.phone FROM students s 
             JOIN users u ON s.user_id = u.id WHERE s.id = $1`,
            [id]
        );
        
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        
        const feeResult = await pool.query(`SELECT * FROM fees WHERE student_id = $1`, [id]);
        const payResult = await pool.query(
            `SELECT * FROM payments WHERE student_id = $1 ORDER BY payment_date DESC`,
            [id]
        );
        
        res.json({
            success: true,
            student: sResult.rows[0],
            fees: feeResult.rows[0] || {},
            payments: payResult.rows || []
        });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.post('/api/accountant/student', verifyToken, checkRole(['accountant']), async (req, res) => {
    const { name, phone, email, admission_no, class: className, section, roll_no, parent_name, parent_phone } = req.body;
    
    if (!name || !phone || !admission_no || !className) {
        return res.status(400).json({ success: false, message: 'Required fields missing' });
    }
    
    try {
        const uResult = await pool.query(
            `INSERT INTO users (name, phone, email, role) VALUES ($1, $2, $3, 'student') RETURNING id`,
            [name, phone, email || null]
        );
        const newUserId = uResult.rows[0].id;
        
        const sResult = await pool.query(
            `INSERT INTO students (user_id, admission_no, class, section, roll_no, parent_name, parent_phone) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
            [newUserId, admission_no, className, section || 'A', roll_no || '00', parent_name, parent_phone]
        );
        const newStudentId = sResult.rows[0].id;
        
        const fsResult = await pool.query(`SELECT total_fee FROM fee_structure WHERE class = $1`, [className]);
        const totalFee = fsResult.rows[0]?.total_fee || 50000;
        
        await pool.query(
            `INSERT INTO fees (student_id, total_amount, paid_amount, due_date, status) 
             VALUES ($1, $2, 0, '2026-12-31', 'due')`,
            [newStudentId, totalFee]
        );
        
        res.json({ success: true, message: 'Student added', student_id: newStudentId });
    } catch (err) {
        console.error('Add student error:', err);
        res.status(500).json({ success: false });
    }
});

app.put('/api/accountant/student/:id', verifyToken, checkRole(['accountant']), async (req, res) => {
    const { id } = req.params;
    const { name, phone, email, class: className, section, roll_no, parent_name, parent_phone, address, reason } = req.body;
    
    try {
        const sResult = await pool.query(
            `SELECT s.*, u.name, u.phone FROM students s JOIN users u ON s.user_id = u.id WHERE s.id = $1`,
            [id]
        );
        
        if (sResult.rows.length === 0) return res.status(404).json({ success: false });
        const oldStudent = sResult.rows[0];
        
        if (name || phone || email) {
            await pool.query(
                `UPDATE users SET name = COALESCE($1, name), phone = COALESCE($2, phone), email = COALESCE($3, email) WHERE id = $4`,
                [name, phone, email, oldStudent.user_id]
            );
        }
        
        await pool.query(
            `UPDATE students SET class = COALESCE($1, class), section = COALESCE($2, section),
                roll_no = COALESCE($3, roll_no), parent_name = COALESCE($4, parent_name),
                parent_phone = COALESCE($5, parent_phone), address = COALESCE($6, address)
             WHERE id = $7`,
            [className, section, roll_no, parent_name, parent_phone, address, id]
        );
        
        res.json({ success: true, message: 'Student updated' });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/accountant/teachers', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT t.*, u.name, u.email, u.phone 
             FROM teachers t JOIN users u ON t.user_id = u.id ORDER BY t.staff_code`
        );
        res.json({ success: true, teachers: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/accountant/teacher/:id', verifyToken, checkRole(['accountant']), async (req, res) => {
    const { id } = req.params;
    
    try {
        const result = await pool.query(
            `SELECT t.*, u.name, u.email, u.phone FROM teachers t 
             JOIN users u ON t.user_id = u.id WHERE t.id = $1`,
            [id]
        );
        
        if (result.rows.length === 0) return res.status(404).json({ success: false });
        res.json({ success: true, teacher: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.post('/api/accountant/teacher', verifyToken, checkRole(['accountant']), async (req, res) => {
    const { name, phone, email, staff_code, subject, designation, is_class_incharge, incharge_class, incharge_section, salary } = req.body;
    
    if (!name || !phone || !staff_code) {
        return res.status(400).json({ success: false, message: 'Required fields missing' });
    }
    
    try {
        const uResult = await pool.query(
            `INSERT INTO users (name, phone, email, role) VALUES ($1, $2, $3, 'teacher') RETURNING id`,
            [name, phone, email || null]
        );
        const newUserId = uResult.rows[0].id;
        
        const tResult = await pool.query(
            `INSERT INTO teachers (user_id, staff_code, designation, subject, is_class_incharge, incharge_class, incharge_section, salary) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id`,
            [newUserId, staff_code, designation || 'Teacher', subject || 'General', 
             is_class_incharge ? 1 : 0, incharge_class || null, incharge_section || null, salary || 0]
        );
        
        res.json({ success: true, message: 'Teacher added', teacher_id: tResult.rows[0].id });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.put('/api/accountant/teacher/:id', verifyToken, checkRole(['accountant']), async (req, res) => {
    const { id } = req.params;
    const { name, phone, email, subject, designation, is_class_incharge, incharge_class, incharge_section, salary, reason } = req.body;
    
    try {
        const tResult = await pool.query(`SELECT * FROM teachers WHERE id = $1`, [id]);
        if (tResult.rows.length === 0) return res.status(404).json({ success: false });
        const oldTeacher = tResult.rows[0];
        
        if (name || phone || email) {
            await pool.query(
                `UPDATE users SET name = COALESCE($1, name), phone = COALESCE($2, phone), email = COALESCE($3, email) WHERE id = $4`,
                [name, phone, email, oldTeacher.user_id]
            );
        }
        
        await pool.query(
            `UPDATE teachers SET subject = COALESCE($1, subject), designation = COALESCE($2, designation),
                is_class_incharge = COALESCE($3, is_class_incharge), incharge_class = $4,
                incharge_section = $5, salary = COALESCE($6, salary)
             WHERE id = $7`,
            [subject, designation, is_class_incharge ? 1 : 0, 
             is_class_incharge ? incharge_class : null, is_class_incharge ? incharge_section : null,
             salary, id]
        );
        
        res.json({ success: true, message: 'Teacher updated' });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.post('/api/accountant/payment', verifyToken, checkRole(['accountant']), async (req, res) => {
    const { student_id, amount, method, transaction_id, notes } = req.body;
    const studentId = parseInt(student_id);
    
    if (!studentId || !amount || amount <= 0) {
        return res.status(400).json({ success: false, message: 'Invalid payment details' });
    }
    
    try {
        const fResult = await pool.query(`SELECT * FROM fees WHERE student_id = $1`, [studentId]);
        if (fResult.rows.length === 0) return res.status(404).json({ success: false, message: 'Fee record not found' });
        
        const fee = fResult.rows[0];
        const newPaidAmount = parseFloat(fee.paid_amount) + parseFloat(amount);
        const totalAmount = parseFloat(fee.total_amount);
        let newStatus = 'partially_paid';
        
        if (newPaidAmount >= totalAmount) newStatus = 'paid';
        else if (newPaidAmount === 0) newStatus = 'due';
        
        await pool.query(
            `UPDATE fees SET paid_amount = $1, status = $2, last_updated = CURRENT_TIMESTAMP WHERE student_id = $3`,
            [newPaidAmount, newStatus, studentId]
        );
        
        const receiptNo = 'RCP' + Date.now().toString().slice(-6);
        
        const pResult = await pool.query(
            `INSERT INTO payments (student_id, amount, method, transaction_id, receipt_number, notes, recorded_by) 
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
            [studentId, amount, method || 'Cash', transaction_id || null, receiptNo, notes || null, req.user.userId]
        );
        
        res.json({
            success: true,
            message: 'Payment recorded',
            payment_id: pResult.rows[0].id,
            receipt_number: receiptNo,
            new_paid: newPaidAmount,
            new_due: totalAmount - newPaidAmount,
            status: newStatus
        });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/accountant/pending-dues', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT s.id, s.admission_no, s.class, s.section, u.name, u.phone,
                    f.total_amount, f.paid_amount, f.due_date, f.status,
                    (f.total_amount - f.paid_amount) as due_amount
             FROM students s 
             JOIN users u ON s.user_id = u.id 
             JOIN fees f ON s.id = f.student_id
             WHERE f.paid_amount < f.total_amount
             ORDER BY due_amount DESC`
        );
        res.json({ success: true, pending: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/accountant/fee-structure', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const result = await pool.query(`SELECT * FROM fee_structure ORDER BY class`);
        res.json({ success: true, structures: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.put('/api/accountant/fee-structure', verifyToken, checkRole(['accountant']), async (req, res) => {
    const { class: className, total_fee, term1, term2, term3 } = req.body;
    
    try {
        await pool.query(
            `INSERT INTO fee_structure (class, total_fee, term1, term2, term3) 
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (class) DO UPDATE SET 
                total_fee = EXCLUDED.total_fee,
                term1 = EXCLUDED.term1,
                term2 = EXCLUDED.term2,
                term3 = EXCLUDED.term3`,
            [className, total_fee, term1, term2, term3]
        );
        res.json({ success: true, message: 'Fee structure updated' });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/accountant/audit-logs', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT al.*, u.name as user_name FROM audit_logs al 
             LEFT JOIN users u ON al.user_id = u.id 
             ORDER BY al.timestamp DESC LIMIT 50`
        );
        res.json({ success: true, logs: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.post('/api/accountant/apply-leave', verifyToken, checkRole(['accountant']), async (req, res) => {
    const { start_date, end_date, reason } = req.body;
    
    if (!start_date || !end_date || !reason) {
        return res.status(400).json({ success: false, message: 'All fields required' });
    }
    
    try {
        const result = await pool.query(
            `INSERT INTO staff_leaves (user_id, role, start_date, end_date, reason, status) 
             VALUES ($1, 'accountant', $2, $3, $4, 'pending') RETURNING id`,
            [req.user.userId, start_date, end_date, reason]
        );
        res.json({ success: true, message: 'Leave sent to Principal', leave_id: result.rows[0].id });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

app.get('/api/accountant/my-leaves', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT * FROM staff_leaves WHERE user_id = $1 AND role = 'accountant'
             ORDER BY created_at DESC`,
            [req.user.userId]
        );
        res.json({ success: true, leaves: result.rows || [] });
    } catch (err) {
        res.status(500).json({ success: false });
    }
});

// ========== START SERVER ============
initDatabase()
    .then(() => {
        app.listen(PORT, () => {
            console.log('\n✅ SGHPS Backend Running (PostgreSQL)!');
            console.log(`📍 Port: ${PORT}`);
            console.log('\n👨‍🎓 Test Credentials:');
            console.log(`   Student: SGHPS-2024-001 / 9876543210`);
            console.log(`   Teacher: TCH-001 / TCH-001`);
            console.log(`   Principal: PR-001 / PR-001`);
            console.log(`   Accountant: ACC-001 / ACC-001\n`);
        });
    })
    .catch(err => {
        console.error('❌ Database init failed:', err);
        process.exit(1);
    });