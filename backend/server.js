const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// ============ DATABASE CONNECTION ============
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'password',
    database: process.env.DB_NAME || 'sghps_db',
});

// Test DB Connection
pool.connect((err) => {
    if (err) {
        console.error('❌ Database connection failed:', err.message);
    } else {
        console.log('✅ Database connected successfully');
    }
});

// ============ MIDDLEWARE ============
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// ============ FILE UPLOAD SETUP ============
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dir = 'uploads/';
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir);
        }
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});
const upload = multer({ storage });

// ============ AUTH MIDDLEWARE ============
const verifyToken = (req, res, next) => {
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
};

const checkRole = (roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ success: false, message: 'Unauthorized' });
        }
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ success: false, message: 'Access denied' });
        }
        next();
    };
};

// ============ AUTH ROUTES ============

// 1. STUDENT LOGIN (Send OTP)
app.post('/api/auth/student/login', async (req, res) => {
    try {
        const { admission_no, phone } = req.body;
        
        // Validate input
        if (!admission_no || !phone) {
            return res.status(400).json({ 
                success: false, 
                message: 'Admission number and phone are required' 
            });
        }
        
        // Check if student exists
        const studentResult = await pool.query(
            `SELECT s.*, u.id as user_id, u.name, u.phone, u.email, u.role 
             FROM students s 
             JOIN users u ON s.user_id = u.id 
             WHERE s.admission_no = $1 AND u.phone = $2`,
            [admission_no, phone]
        );
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found. Please check Admission Number and Phone.' 
            });
        }
        
        const student = studentResult.rows[0];
        
        // Generate OTP (6 digit)
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        
        // Delete old OTPs
        await pool.query(
            `DELETE FROM otp_requests WHERE user_id = $1 AND used = false`,
            [student.user_id]
        );
        
        // Store OTP
        await pool.query(
            `INSERT INTO otp_requests (user_id, otp, expires_at) 
             VALUES ($1, $2, NOW() + INTERVAL '5 minutes')`,
            [student.user_id, otp]
        );
        
        console.log(`📱 OTP for ${student.name}: ${otp}`);
        
        res.json({
            success: true,
            message: 'OTP sent to your registered mobile number',
            userId: student.user_id,
            // In production, remove this testOtp
            testOtp: otp
        });
        
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 2. VERIFY OTP
app.post('/api/auth/verify-otp', async (req, res) => {
    try {
        const { userId, otp } = req.body;
        
        if (!userId || !otp) {
            return res.status(400).json({ 
                success: false, 
                message: 'User ID and OTP are required' 
            });
        }
        
        // Check OTP
        const otpResult = await pool.query(
            `SELECT * FROM otp_requests 
             WHERE user_id = $1 AND otp = $2 
             AND expires_at > NOW() AND used = false`,
            [userId, otp]
        );
        
        if (otpResult.rows.length === 0) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid or expired OTP' 
            });
        }
        
        // Mark OTP as used
        await pool.query(
            `UPDATE otp_requests SET used = true WHERE id = $1`,
            [otpResult.rows[0].id]
        );
        
        // Get user details
        const userResult = await pool.query(
            `SELECT id, name, email, phone, role FROM users WHERE id = $1`,
            [userId]
        );
        
        if (userResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'User not found' 
            });
        }
        
        const user = userResult.rows[0];
        
        // Generate JWT Token
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
        
    } catch (error) {
        console.error('OTP verification error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 3. TEACHER LOGIN
app.post('/api/auth/teacher/login', async (req, res) => {
    try {
        const { staff_code, password } = req.body;
        
        if (!staff_code || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'Staff code and password required' 
            });
        }
        
        const result = await pool.query(
            `SELECT u.*, t.staff_code 
             FROM teachers t 
             JOIN users u ON t.user_id = u.id 
             WHERE t.staff_code = $1`,
            [staff_code]
        );
        
        if (result.rows.length === 0) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid staff code' 
            });
        }
        
        const user = result.rows[0];
        
        // In production, check hashed password
        // For demo, using staff_code as password
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
        
    } catch (error) {
        console.error('Teacher login error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 4. PRINCIPAL LOGIN
app.post('/api/auth/principal/login', async (req, res) => {
    try {
        const { principal_code, password } = req.body;
        
        if (!principal_code || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'Principal code and password required' 
            });
        }
        
        const result = await pool.query(
            `SELECT u.*, p.principal_code 
             FROM principals p 
             JOIN users u ON p.user_id = u.id 
             WHERE p.principal_code = $1`,
            [principal_code]
        );
        
        if (result.rows.length === 0) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid principal code' 
            });
        }
        
        const user = result.rows[0];
        
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
        
    } catch (error) {
        console.error('Principal login error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 5. ACCOUNTANT LOGIN
app.post('/api/auth/accountant/login', async (req, res) => {
    try {
        const { accountant_code, password } = req.body;
        
        if (!accountant_code || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'Accountant code and password required' 
            });
        }
        
        const result = await pool.query(
            `SELECT u.*, a.accountant_code 
             FROM accountants a 
             JOIN users u ON a.user_id = u.id 
             WHERE a.accountant_code = $1`,
            [accountant_code]
        );
        
        if (result.rows.length === 0) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid accountant code' 
            });
        }
        
        const user = result.rows[0];
        
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
        
    } catch (error) {
        console.error('Accountant login error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// ============ STUDENT ROUTES ============

// 1. GET STUDENT PROFILE
app.get('/api/students/profile', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const result = await pool.query(
            `SELECT s.*, u.name, u.email, u.phone, u.role 
             FROM students s 
             JOIN users u ON s.user_id = u.id 
             WHERE u.id = $1`,
            [userId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        res.json({
            success: true,
            student: result.rows[0]
        });
        
    } catch (error) {
        console.error('Profile error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 2. GET STUDENT ATTENDANCE
app.get('/api/students/attendance', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        // Get student id
        const studentResult = await pool.query(
            `SELECT id FROM students WHERE user_id = $1`,
            [userId]
        );
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        const studentId = studentResult.rows[0].id;
        
        // Get attendance for last 30 days
        const attendanceResult = await pool.query(
            `SELECT date, status, 
             COUNT(*) OVER (PARTITION BY status) as total 
             FROM attendance 
             WHERE student_id = $1 
             AND date >= CURRENT_DATE - INTERVAL '30 days'
             ORDER BY date DESC`,
            [studentId]
        );
        
        // Calculate attendance percentage
        const total = attendanceResult.rows.length;
        const present = attendanceResult.rows.filter(a => a.status === 'present').length;
        const percentage = total > 0 ? Math.round((present / total) * 100) : 0;
        
        res.json({
            success: true,
            attendance: {
                percentage,
                total,
                present,
                absent: total - present,
                records: attendanceResult.rows
            }
        });
        
    } catch (error) {
        console.error('Attendance error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 3. GET STUDENT FEES
app.get('/api/students/fees', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const studentResult = await pool.query(
            `SELECT id FROM students WHERE user_id = $1`,
            [userId]
        );
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        const studentId = studentResult.rows[0].id;
        
        const feeResult = await pool.query(
            `SELECT * FROM fees WHERE student_id = $1 ORDER BY created_at DESC`,
            [studentId]
        );
        
        res.json({
            success: true,
            fees: feeResult.rows
        });
        
    } catch (error) {
        console.error('Fees error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 4. GET STUDENT HOMEWORK
app.get('/api/students/homework', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const studentResult = await pool.query(
            `SELECT class, section FROM students WHERE user_id = $1`,
            [userId]
        );
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        const { class: studentClass, section } = studentResult.rows[0];
        
        const homeworkResult = await pool.query(
            `SELECT h.*, u.name as teacher_name 
             FROM homework h 
             JOIN users u ON h.teacher_id = u.id 
             WHERE h.class = $1 AND h.section = $2 
             ORDER BY h.deadline ASC`,
            [studentClass, section]
        );
        
        res.json({
            success: true,
            homework: homeworkResult.rows
        });
        
    } catch (error) {
        console.error('Homework error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 5. GET STUDENT TIMETABLE
app.get('/api/students/timetable', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const studentResult = await pool.query(
            `SELECT class, section FROM students WHERE user_id = $1`,
            [userId]
        );
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        const { class: studentClass, section } = studentResult.rows[0];
        
        const timetableResult = await pool.query(
            `SELECT * FROM timetable 
             WHERE class = $1 AND section = $2 
             ORDER BY day, period`,
            [studentClass, section]
        );
        
        res.json({
            success: true,
            timetable: timetableResult.rows
        });
        
    } catch (error) {
        console.error('Timetable error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 6. APPLY LEAVE
app.post('/api/students/leave', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        const { start_date, end_date, reason } = req.body;
        
        if (!start_date || !end_date || !reason) {
            return res.status(400).json({ 
                success: false, 
                message: 'All fields are required' 
            });
        }
        
        const studentResult = await pool.query(
            `SELECT id FROM students WHERE user_id = $1`,
            [userId]
        );
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        const studentId = studentResult.rows[0].id;
        
        const result = await pool.query(
            `INSERT INTO leaves (student_id, start_date, end_date, reason, status) 
             VALUES ($1, $2, $3, $4, 'pending') 
             RETURNING *`,
            [studentId, start_date, end_date, reason]
        );
        
        res.json({
            success: true,
            message: 'Leave application submitted successfully',
            leave: result.rows[0]
        });
        
    } catch (error) {
        console.error('Leave error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 7. GET STUDENT LEAVES
app.get('/api/students/leaves', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const studentResult = await pool.query(
            `SELECT id FROM students WHERE user_id = $1`,
            [userId]
        );
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        const studentId = studentResult.rows[0].id;
        
        const leaveResult = await pool.query(
            `SELECT * FROM leaves 
             WHERE student_id = $1 
             ORDER BY created_at DESC`,
            [studentId]
        );
        
        res.json({
            success: true,
            leaves: leaveResult.rows
        });
        
    } catch (error) {
        console.error('Leaves error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 8. GET STUDENT RESULTS
app.get('/api/students/results', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const studentResult = await pool.query(
            `SELECT id FROM students WHERE user_id = $1`,
            [userId]
        );
        
        if (studentResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        const studentId = studentResult.rows[0].id;
        
        const resultResult = await pool.query(
            `SELECT r.*, e.name as exam_name, e.subject 
             FROM results r 
             JOIN exams e ON r.exam_id = e.id 
             WHERE r.student_id = $1 
             ORDER BY e.created_at DESC`,
            [studentId]
        );
        
        res.json({
            success: true,
            results: resultResult.rows
        });
        
    } catch (error) {
        console.error('Results error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// ============ TEACHER ROUTES ============

// 1. GET TEACHER CLASSES
app.get('/api/teacher/classes', verifyToken, checkRole(['teacher']), async (req, res) => {
    try {
        const userId = req.user.userId;
        
        const result = await pool.query(
            `SELECT t.*, u.name as teacher_name 
             FROM teacher_classes t 
             JOIN users u ON t.teacher_id = u.id 
             WHERE t.teacher_id = $1`,
            [userId]
        );
        
        res.json({
            success: true,
            classes: result.rows
        });
        
    } catch (error) {
        console.error('Teacher classes error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 2. MARK ATTENDANCE
app.post('/api/teacher/attendance', verifyToken, checkRole(['teacher']), async (req, res) => {
    try {
        const teacherId = req.user.userId;
        const { class: className, section, date, attendance } = req.body;
        
        if (!className || !section || !date || !attendance) {
            return res.status(400).json({ 
                success: false, 
                message: 'All fields are required' 
            });
        }
        
        // Insert attendance records
        for (const record of attendance) {
            await pool.query(
                `INSERT INTO attendance (student_id, date, status, teacher_id) 
                 VALUES ($1, $2, $3, $4)`,
                [record.student_id, date, record.status, teacherId]
            );
        }
        
        res.json({
            success: true,
            message: 'Attendance marked successfully'
        });
        
    } catch (error) {
        console.error('Mark attendance error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 3. CREATE HOMEWORK
app.post('/api/teacher/homework', verifyToken, checkRole(['teacher']), upload.single('attachment'), async (req, res) => {
    try {
        const teacherId = req.user.userId;
        const { class: className, section, subject, title, description, deadline } = req.body;
        const attachment = req.file ? req.file.filename : null;
        
        if (!className || !section || !subject || !title || !deadline) {
            return res.status(400).json({ 
                success: false, 
                message: 'All fields are required' 
            });
        }
        
        const result = await pool.query(
            `INSERT INTO homework (teacher_id, class, section, subject, title, description, deadline, attachment_url) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
             RETURNING *`,
            [teacherId, className, section, subject, title, description, deadline, attachment]
        );
        
        res.json({
            success: true,
            message: 'Homework created successfully',
            homework: result.rows[0]
        });
        
    } catch (error) {
        console.error('Create homework error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 4. GET HOMEWORK SUBMISSIONS
app.get('/api/teacher/homework/:homeworkId/submissions', verifyToken, checkRole(['teacher']), async (req, res) => {
    try {
        const { homeworkId } = req.params;
        
        const result = await pool.query(
            `SELECT hs.*, s.admission_no, u.name as student_name 
             FROM homework_submissions hs 
             JOIN students s ON hs.student_id = s.id 
             JOIN users u ON s.user_id = u.id 
             WHERE hs.homework_id = $1`,
            [homeworkId]
        );
        
        res.json({
            success: true,
            submissions: result.rows
        });
        
    } catch (error) {
        console.error('Get submissions error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// ============ PRINCIPAL ROUTES ============

// 1. GET SCHOOL STATISTICS
app.get('/api/principal/statistics', verifyToken, checkRole(['principal']), async (req, res) => {
    try {
        const totalStudents = await pool.query('SELECT COUNT(*) FROM students');
        const totalTeachers = await pool.query('SELECT COUNT(*) FROM teachers');
        const totalClasses = await pool.query('SELECT COUNT(DISTINCT class) FROM students');
        const todayAttendance = await pool.query(
            `SELECT COUNT(*) as present 
             FROM attendance 
             WHERE date = CURRENT_DATE AND status = 'present'`
        );
        
        res.json({
            success: true,
            statistics: {
                totalStudents: parseInt(totalStudents.rows[0].count),
                totalTeachers: parseInt(totalTeachers.rows[0].count),
                totalClasses: parseInt(totalClasses.rows[0].count),
                todayPresent: parseInt(todayAttendance.rows[0].present)
            }
        });
        
    } catch (error) {
        console.error('Statistics error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 2. GET ALL CLASSES WITH ATTENDANCE
app.get('/api/principal/classes', verifyToken, checkRole(['principal']), async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT DISTINCT class, section, 
             (SELECT COUNT(*) FROM students s2 WHERE s2.class = s.class AND s2.section = s.section) as total_students,
             (SELECT COUNT(*) FROM attendance a WHERE a.student_id IN 
              (SELECT id FROM students s3 WHERE s3.class = s.class AND s3.section = s.section) 
              AND a.date = CURRENT_DATE AND a.status = 'present') as present_count
             FROM students s 
             ORDER BY class, section`
        );
        
        res.json({
            success: true,
            classes: result.rows
        });
        
    } catch (error) {
        console.error('Classes error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 3. GET STUDENT DETAILS FOR PRINCIPAL
app.get('/api/principal/student/:studentId', verifyToken, checkRole(['principal']), async (req, res) => {
    try {
        const { studentId } = req.params;
        
        const result = await pool.query(
            `SELECT s.*, u.name, u.email, u.phone 
             FROM students s 
             JOIN users u ON s.user_id = u.id 
             WHERE s.id = $1`,
            [studentId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Student not found' 
            });
        }
        
        const student = result.rows[0];
        
        // Get attendance
        const attendanceResult = await pool.query(
            `SELECT date, status FROM attendance 
             WHERE student_id = $1 
             ORDER BY date DESC LIMIT 30`,
            [studentId]
        );
        
        // Get fees
        const feeResult = await pool.query(
            `SELECT * FROM fees WHERE student_id = $1`,
            [studentId]
        );
        
        // Get leaves
        const leaveResult = await pool.query(
            `SELECT * FROM leaves WHERE student_id = $1`,
            [studentId]
        );
        
        res.json({
            success: true,
            student: {
                ...student,
                attendance: attendanceResult.rows,
                fees: feeResult.rows,
                leaves: leaveResult.rows
            }
        });
        
    } catch (error) {
        console.error('Student detail error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 4. APPROVE LEAVE
app.put('/api/principal/leave/:leaveId/approve', verifyToken, checkRole(['principal']), async (req, res) => {
    try {
        const { leaveId } = req.params;
        const { status } = req.body;
        
        if (!['approved', 'rejected'].includes(status)) {
            return res.status(400).json({ 
                success: false, 
                message: 'Invalid status' 
            });
        }
        
        const result = await pool.query(
            `UPDATE leaves SET status = $1, approved_at = NOW() 
             WHERE id = $2 RETURNING *`,
            [status, leaveId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Leave not found' 
            });
        }
        
        res.json({
            success: true,
            message: `Leave ${status}`,
            leave: result.rows[0]
        });
        
    } catch (error) {
        console.error('Approve leave error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// ============ ACCOUNTANT ROUTES ============

// 1. CREATE STUDENT (Accountant)
app.post('/api/accountant/student', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const { name, phone, email, admission_no, class: className, section, parent_phone, parent_email } = req.body;
        
        if (!name || !phone || !admission_no || !className) {
            return res.status(400).json({ 
                success: false, 
                message: 'Name, phone, admission number and class are required' 
            });
        }
        
        // Check if admission number exists
        const existingStudent = await pool.query(
            'SELECT id FROM students WHERE admission_no = $1',
            [admission_no]
        );
        
        if (existingStudent.rows.length > 0) {
            return res.status(400).json({ 
                success: false, 
                message: 'Admission number already exists' 
            });
        }
        
        // Create user
        const userResult = await pool.query(
            `INSERT INTO users (name, phone, email, role) 
             VALUES ($1, $2, $3, 'student') RETURNING id`,
            [name, phone, email || null]
        );
        
        const userId = userResult.rows[0].id;
        
        // Create student
        const studentResult = await pool.query(
            `INSERT INTO students (user_id, admission_no, class, section, parent_phone, parent_email) 
             VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
            [userId, admission_no, className, section || null, parent_phone || null, parent_email || null]
        );
        
        res.json({
            success: true,
            message: 'Student created successfully',
            student: studentResult.rows[0]
        });
        
    } catch (error) {
        console.error('Create student error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 2. RECORD PAYMENT
app.post('/api/accountant/payment', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const { student_id, amount, payment_method, transaction_id, receipt_number } = req.body;
        
        if (!student_id || !amount) {
            return res.status(400).json({ 
                success: false, 
                message: 'Student ID and amount are required' 
            });
        }
        
        // Get current fee
        const feeResult = await pool.query(
            `SELECT * FROM fees WHERE student_id = $1 ORDER BY created_at DESC LIMIT 1`,
            [student_id]
        );
        
        if (feeResult.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'Fee record not found' 
            });
        }
        
        const currentFee = feeResult.rows[0];
        const newPaidAmount = parseFloat(currentFee.paid_amount) + parseFloat(amount);
        const totalAmount = parseFloat(currentFee.total_amount);
        
        let status = 'partially_paid';
        if (newPaidAmount >= totalAmount) {
            status = 'paid';
        }
        
        // Update fee
        await pool.query(
            `UPDATE fees SET paid_amount = $1, status = $2 WHERE id = $3`,
            [newPaidAmount, status, currentFee.id]
        );
        
        // Record payment
        const paymentResult = await pool.query(
            `INSERT INTO payments (student_id, amount, payment_method, transaction_id, receipt_number, status) 
             VALUES ($1, $2, $3, $4, $5, 'completed') RETURNING *`,
            [student_id, amount, payment_method || 'cash', transaction_id || null, receipt_number || null]
        );
        
        res.json({
            success: true,
            message: 'Payment recorded successfully',
            payment: paymentResult.rows[0]
        });
        
    } catch (error) {
        console.error('Record payment error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// 3. GET FEE REPORTS
app.get('/api/accountant/fee-report', verifyToken, checkRole(['accountant']), async (req, res) => {
    try {
        const { class: className, section } = req.query;
        
        let query = `
            SELECT s.id, s.admission_no, s.class, s.section, 
                   u.name, f.total_amount, f.paid_amount, f.status, f.due_date
            FROM students s 
            JOIN users u ON s.user_id = u.id 
            JOIN fees f ON s.id = f.student_id
            WHERE 1=1
        `;
        const params = [];
        
        if (className) {
            query += ` AND s.class = $${params.length + 1}`;
            params.push(className);
        }
        if (section) {
            query += ` AND s.section = $${params.length + 1}`;
            params.push(section);
        }
        
        const result = await pool.query(query, params);
        
        res.json({
            success: true,
            report: result.rows
        });
        
    } catch (error) {
        console.error('Fee report error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// ============ HEALTH CHECK ============
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'SGHPS Backend Running',
        time: new Date().toISOString()
    });
});

// ============ START SERVER ============
app.listen(PORT, () => {
    console.log(`✅ SGHPS Backend running on http://localhost:${PORT}`);
    console.log(`📚 API Documentation: http://localhost:${PORT}/api/health`);
    console.log(`👨‍🎓 Student Login: POST /api/auth/student/login`);
    console.log(`🔑 Verify OTP: POST /api/auth/verify-otp`);
});