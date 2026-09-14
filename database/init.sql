-- SGHPS Database Schema

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(15) UNIQUE,
    password_hash VARCHAR(255),
    role VARCHAR(20) CHECK (role IN ('student', 'teacher', 'principal', 'accountant')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Students Table
CREATE TABLE IF NOT EXISTS students (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    admission_no VARCHAR(20) UNIQUE NOT NULL,
    class VARCHAR(10),
    section VARCHAR(5),
    roll_no VARCHAR(10),
    date_of_birth DATE,
    gender VARCHAR(10),
    parent_phone VARCHAR(15),
    parent_email VARCHAR(100),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Teachers Table
CREATE TABLE IF NOT EXISTS teachers (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    staff_code VARCHAR(20) UNIQUE NOT NULL,
    designation VARCHAR(50),
    qualification VARCHAR(100),
    joined_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Principals Table
CREATE TABLE IF NOT EXISTS principals (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    principal_code VARCHAR(20) UNIQUE NOT NULL,
    joined_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Accountants Table
CREATE TABLE IF NOT EXISTS accountants (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    accountant_code VARCHAR(20) UNIQUE NOT NULL,
    joined_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Teacher Classes Assignment
CREATE TABLE IF NOT EXISTS teacher_classes (
    id SERIAL PRIMARY KEY,
    teacher_id INTEGER REFERENCES teachers(id) ON DELETE CASCADE,
    class VARCHAR(10),
    section VARCHAR(5),
    subject VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attendance Table
CREATE TABLE IF NOT EXISTS attendance (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(10) CHECK (status IN ('present', 'absent', 'late')),
    teacher_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, date)
);

-- Homework Table
CREATE TABLE IF NOT EXISTS homework (
    id SERIAL PRIMARY KEY,
    teacher_id INTEGER REFERENCES users(id),
    class VARCHAR(10),
    section VARCHAR(5),
    subject VARCHAR(50),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    deadline DATE,
    attachment_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Homework Submissions
CREATE TABLE IF NOT EXISTS homework_submissions (
    id SERIAL PRIMARY KEY,
    homework_id INTEGER REFERENCES homework(id) ON DELETE CASCADE,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    content TEXT,
    attachment_url VARCHAR(255),
    status VARCHAR(20) CHECK (status IN ('submitted', 'late', 'graded')),
    grade VARCHAR(5),
    feedback TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fees Table
CREATE TABLE IF NOT EXISTS fees (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    total_amount DECIMAL(10,2) NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    due_date DATE,
    status VARCHAR(20) CHECK (status IN ('paid', 'partially_paid', 'due', 'overdue')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments Table
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) CHECK (payment_method IN ('cash', 'card', 'online', 'bank_transfer')),
    transaction_id VARCHAR(100),
    receipt_number VARCHAR(50),
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed')),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exams Table
CREATE TABLE IF NOT EXISTS exams (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    subject VARCHAR(50),
    class VARCHAR(10),
    section VARCHAR(5),
    exam_date DATE,
    start_time TIME,
    end_time TIME,
    total_marks INTEGER,
    passing_marks INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Results Table
CREATE TABLE IF NOT EXISTS results (
    id SERIAL PRIMARY KEY,
    exam_id INTEGER REFERENCES exams(id) ON DELETE CASCADE,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    marks_obtained DECIMAL(5,2),
    grade VARCHAR(5),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(exam_id, student_id)
);

-- Timetable Table
CREATE TABLE IF NOT EXISTS timetable (
    id SERIAL PRIMARY KEY,
    class VARCHAR(10),
    section VARCHAR(5),
    day VARCHAR(10) CHECK (day IN ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday')),
    period INTEGER,
    subject VARCHAR(50),
    teacher_name VARCHAR(100),
    room VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Leaves Table
CREATE TABLE IF NOT EXISTS leaves (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status VARCHAR(20) CHECK (status IN ('pending', 'approved', 'rejected')),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT,
    type VARCHAR(30) CHECK (type IN ('school', 'homework', 'exam', 'fees', 'leave', 'documents', 'events', 'transport')),
    priority VARCHAR(20) CHECK (priority IN ('normal', 'important', 'urgent')),
    is_read BOOLEAN DEFAULT FALSE,
    link VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Events Table
CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    event_date DATE NOT NULL,
    event_time TIME,
    location VARCHAR(100),
    type VARCHAR(30) CHECK (type IN ('holiday', 'exam', 'ptm', 'event', 'activity')),
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Certificates Table
CREATE TABLE IF NOT EXISTS certificates (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    type VARCHAR(30) CHECK (type IN ('bonafide', 'character', 'achievement', 'participation')),
    title VARCHAR(200),
    description TEXT,
    issue_date DATE DEFAULT CURRENT_DATE,
    certificate_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Library Books
CREATE TABLE IF NOT EXISTS books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100),
    isbn VARCHAR(20),
    category VARCHAR(50),
    total_copies INTEGER DEFAULT 1,
    available_copies INTEGER DEFAULT 1,
    location VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Book Issues
CREATE TABLE IF NOT EXISTS book_issues (
    id SERIAL PRIMARY KEY,
    book_id INTEGER REFERENCES books(id) ON DELETE CASCADE,
    student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
    issue_date DATE DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    return_date DATE,
    status VARCHAR(20) CHECK (status IN ('issued', 'returned', 'overdue')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    details JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- School Settings
CREATE TABLE IF NOT EXISTS school_settings (
    id SERIAL PRIMARY KEY,
    school_name VARCHAR(200),
    logo_url VARCHAR(255),
    address TEXT,
    contact_phone VARCHAR(15),
    contact_email VARCHAR(100),
    academic_session VARCHAR(20),
    payment_url VARCHAR(255),
    branding JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- OTP Requests
CREATE TABLE IF NOT EXISTS otp_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============ INDEXES ============
CREATE INDEX idx_attendance_student_date ON attendance(student_id, date);
CREATE INDEX idx_homework_class_section ON homework(class, section);
CREATE INDEX idx_fees_student ON fees(student_id);
CREATE INDEX idx_payments_student ON payments(student_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_leaves_student ON leaves(student_id);
CREATE INDEX idx_otp_requests_user ON otp_requests(user_id);
CREATE INDEX idx_otp_requests_otp ON otp_requests(otp);

-- ============ TEST DATA ============

-- Insert Users
INSERT INTO users (name, email, phone, role) VALUES
('Manavjot Singh', 'manavjot@test.com', '9876543210', 'student'),
('Navdeep Singh', 'navdeep@test.com', '9876543211', 'teacher'),
('Jaskaran Singh', 'jaskaran@test.com', '9876543212', 'principal'),
('Amritpal Singh', 'amritpal@test.com', '9876543213', 'accountant');

-- Insert Student
INSERT INTO students (user_id, admission_no, class, section, roll_no, parent_phone) VALUES
(1, 'SGHPS-2024-001', 'XII', 'A', '01', '9876543214');

-- Insert Teacher
INSERT INTO teachers (user_id, staff_code, designation) VALUES
(2, 'TCH-001', 'Senior Teacher');

-- Insert Principal
INSERT INTO principals (user_id, principal_code) VALUES
(3, 'PR-001');

-- Insert Accountant
INSERT INTO accountants (user_id, accountant_code) VALUES
(4, 'ACC-001');

-- Insert Sample Fee
INSERT INTO fees (student_id, total_amount, paid_amount, due_date, status) VALUES
(1, 50000, 35000, '2024-12-31', 'partially_paid');

-- Insert Sample Attendance
INSERT INTO attendance (student_id, date, status, teacher_id) VALUES
(1, CURRENT_DATE, 'present', 2),
(1, CURRENT_DATE - INTERVAL '1 day', 'present', 2),
(1, CURRENT_DATE - INTERVAL '2 days', 'absent', 2),
(1, CURRENT_DATE - INTERVAL '3 days', 'present', 2),
(1, CURRENT_DATE - INTERVAL '4 days', 'present', 2);

-- Insert Sample Homework
INSERT INTO homework (teacher_id, class, section, subject, title, description, deadline) VALUES
(2, 'XII', 'A', 'Mathematics', 'Chapter 5: Calculus', 'Solve all exercises from Chapter 5', '2024-12-20');

-- Insert Sample Timetable
INSERT INTO timetable (class, section, day, period, subject, teacher_name, room) VALUES
('XII', 'A', 'monday', 1, 'Mathematics', 'Navdeep Singh', 'Room 101'),
('XII', 'A', 'monday', 2, 'Physics', 'Dr. Sharma', 'Room 102'),
('XII', 'A', 'tuesday', 1, 'Chemistry', 'Ms. Gupta', 'Room 103'),
('XII', 'A', 'tuesday', 2, 'English', 'Mr. Kumar', 'Room 104');

-- Insert Sample Leaves
INSERT INTO leaves (student_id, start_date, end_date, reason, status) VALUES
(1, '2024-12-15', '2024-12-16', 'Family event', 'pending');

-- Insert Sample Events
INSERT INTO events (title, description, event_date, type) VALUES
('Winter Break', 'School will remain closed for winter break', '2024-12-25', 'holiday'),
('Annual Sports Day', 'Annual sports competition', '2025-01-15', 'event');

-- Insert Sample Notifications
INSERT INTO notifications (user_id, title, message, type, priority) VALUES
(1, 'Homework Assigned', 'New homework assigned in Mathematics', 'homework', 'normal'),
(1, 'Fee Reminder', 'Fee payment due in 10 days', 'fees', 'important');