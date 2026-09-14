-- OTP Requests Table
CREATE TABLE otp_requests (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster OTP lookups
CREATE INDEX idx_otp_requests_user_id ON otp_requests(user_id);
CREATE INDEX idx_otp_requests_otp ON otp_requests(otp);