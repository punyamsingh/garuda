-- Drop the tables if they exist
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS offices CASCADE;
DROP TABLE IF EXISTS employee_attendance CASCADE;
DROP TABLE IF EXISTS employee_offices CASCADE;
DROP TABLE IF EXISTS working_hours_data CASCADE;

-- Table for storing employees (for simplicity, only ID and name)
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL
);

-- Table for storing office locations
CREATE TABLE offices (
    office_id SERIAL PRIMARY KEY,
    office_name VARCHAR(100) NOT NULL,
    office_latitude DOUBLE PRECISION NOT NULL,
    office_longitude DOUBLE PRECISION NOT NULL
);

-- Table for storing attendance events (geolocation/manual mode)
CREATE TABLE employee_attendance (
    attendance_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    office_id INT,
    event_type TEXT CHECK (event_type IN ('checkin', 'checkout')),
    event_time TIMESTAMPTZ NOT NULL,
    mode TEXT CHECK (mode IN ('geolocation', 'manual')),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (office_id) REFERENCES offices(office_id)
);

-- Table to store employee and office mappings (editable by managers only)
CREATE TABLE employee_offices (
    employee_id INT NOT NULL,
    office_id INT NOT NULL,
    PRIMARY KEY (employee_id, office_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (office_id) REFERENCES offices(office_id)
);

-- Table to store working hours data per day, week, and month
CREATE TABLE working_hours_data (
    employee_id INT NOT NULL,
    mode TEXT CHECK (mode IN ('geolocation', 'manual')),
    day DATE,
    total_hours DOUBLE PRECISION DEFAULT 0,
    week DATE,
    month DATE,
    PRIMARY KEY (employee_id, day, mode),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Function to calculate working hours for a day
CREATE OR REPLACE FUNCTION calculate_working_hours_day(emp_id INT, work_day DATE) RETURNS DOUBLE PRECISION AS $$
DECLARE
    checkin_time TIMESTAMPTZ;
    checkout_time TIMESTAMPTZ;
    total_working_hours DOUBLE PRECISION := 0;
BEGIN
    FOR checkin_time, checkout_time IN
        (SELECT a1.event_time AS checkin_time, a2.event_time AS checkout_time
         FROM employee_attendance a1
         JOIN employee_attendance a2 ON a1.employee_id = a2.employee_id
         WHERE a1.employee_id = emp_id
           AND a1.event_type = 'checkin'
           AND a2.event_type = 'checkout'
           AND a1.event_time < a2.event_time
           AND DATE(a1.event_time) = work_day
           AND DATE(a2.event_time) = work_day)
    LOOP
        total_working_hours := total_working_hours + EXTRACT(EPOCH FROM (checkout_time - checkin_time)) / 3600;
    END LOOP;

    RETURN total_working_hours;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate working hours per week
CREATE OR REPLACE FUNCTION calculate_working_hours_week(emp_id INT, work_week DATE, mode_input TEXT DEFAULT NULL) RETURNS DOUBLE PRECISION AS $$
DECLARE
    work_day DATE;
    weekly_hours DOUBLE PRECISION := 0;
BEGIN
    FOR work_day IN (SELECT generate_series(work_week, work_week + interval '6 days', '1 day')::DATE)
    LOOP
        weekly_hours := weekly_hours + COALESCE(calculate_working_hours_day(emp_id, work_day), 0);
    END LOOP;

    RETURN weekly_hours;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate working hours per month
CREATE OR REPLACE FUNCTION calculate_working_hours_month(emp_id INT, work_month DATE, mode_input TEXT DEFAULT NULL) RETURNS DOUBLE PRECISION AS $$
DECLARE
    start_date DATE := date_trunc('month', work_month)::DATE;
    end_date DATE := date_trunc('month', work_month + interval '1 month')::DATE - 1;
    monthly_hours DOUBLE PRECISION := 0;
    work_day DATE;
BEGIN
    FOR work_day IN (SELECT generate_series(start_date, end_date, '1 day')::DATE)
    LOOP
        monthly_hours := monthly_hours + COALESCE(calculate_working_hours_day(emp_id, work_day), 0);
    END LOOP;

    RETURN monthly_hours;
END;
$$ LANGUAGE plpgsql;

-- Trigger on checkout event to calculate and store working hours for the day
CREATE OR REPLACE FUNCTION update_working_hours_on_checkout() RETURNS TRIGGER AS $$
DECLARE
    day_hours DOUBLE PRECISION;
    week_start DATE := date_trunc('week', NEW.event_time)::DATE;
    month_start DATE := date_trunc('month', NEW.event_time)::DATE;
BEGIN
    -- Calculate working hours for the day
    day_hours := calculate_working_hours_day(NEW.employee_id, DATE(NEW.event_time));

    -- Update or insert the working hours for the day, week, and month
    INSERT INTO working_hours_data (employee_id, mode, day, total_hours, week, month)
    VALUES (NEW.employee_id, NEW.mode, DATE(NEW.event_time), day_hours, week_start, month_start)
    ON CONFLICT (employee_id, day, mode) DO UPDATE 
    SET total_hours = EXCLUDED.total_hours;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update working hours on checkout
CREATE TRIGGER trigger_on_checkout
AFTER INSERT ON employee_attendance
FOR EACH ROW
WHEN (NEW.event_type = 'checkout')
EXECUTE FUNCTION update_working_hours_on_checkout();
