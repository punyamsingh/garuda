-- Start a transaction
BEGIN;

-- Table structure for `employee`
CREATE TABLE public.employee (
    Employee_ID serial PRIMARY KEY,
    First_Name text NOT NULL,
    Last_Name text,
    DOB date,
    Email text UNIQUE NOT NULL,
    Phone_Number text UNIQUE,
    Hire_Date date,
    Picture_URL text
);

-- Table structure for `office`
CREATE TABLE public.office (
    Office_ID serial PRIMARY KEY,
    Office_Name text NOT NULL,
    Latitude double precision NOT NULL,
    Longitude double precision NOT NULL,
    Radius double precision DEFAULT 200 -- 200 meters radius for geolocation tracking
);

-- Table structure for employee-to-office assignment
CREATE TABLE public.employee_office (
    Employee_ID integer NOT NULL,
    Office_ID integer NOT NULL,
    Manager_ID integer NOT NULL, -- Only manager can assign offices
    PRIMARY KEY (Employee_ID, Office_ID),
    CONSTRAINT fk_employee
        FOREIGN KEY(Employee_ID) 
        REFERENCES public.employee(Employee_ID),
    CONSTRAINT fk_office
        FOREIGN KEY(Office_ID) 
        REFERENCES public.office(Office_ID),
    CONSTRAINT fk_manager
        FOREIGN KEY(Manager_ID) 
        REFERENCES public.employee(Employee_ID) -- Managers are employees too
);

-- Table structure for `attendance_event`
CREATE TABLE public.attendance_event (
    Event_ID serial PRIMARY KEY,
    Employee_ID integer NOT NULL,
    Office_ID integer, -- Nullable for manual check-ins
    Event_Type text NOT NULL CHECK (Event_Type IN ('CheckIn', 'CheckOut')), -- Check-in or Check-out
    Event_Time timestamp NOT NULL,
    Latitude double precision,
    Longitude double precision,
    Mode text NOT NULL CHECK (Mode IN ('Geolocation', 'Manual')), -- Mode of check-in
    CONSTRAINT fk_employee
        FOREIGN KEY(Employee_ID) 
        REFERENCES public.employee(Employee_ID),
    CONSTRAINT fk_office
        FOREIGN KEY(Office_ID) 
        REFERENCES public.office(Office_ID)
);

-- Table structure for storing calculated working hours
CREATE TABLE public.working_hours (
    Employee_ID integer NOT NULL,
    Day date NOT NULL,
    Week integer NOT NULL,
    Month integer NOT NULL,
    Year integer NOT NULL,
    Mode text CHECK (Mode IN ('Geolocation', 'Manual', 'All')) DEFAULT 'All',
    Total_Hours interval NOT NULL,
    PRIMARY KEY (Employee_ID, Day, Mode),
    CONSTRAINT fk_employee
        FOREIGN KEY(Employee_ID) 
        REFERENCES public.employee(Employee_ID)
);

-- Function to calculate working hours for a single day
CREATE OR REPLACE FUNCTION calculate_working_hours(employee_id INT, day DATE, mode_filter TEXT DEFAULT 'All') 
RETURNS INTERVAL AS $$
DECLARE 
    check_in_time TIMESTAMP;
    check_out_time TIMESTAMP;
    total_time INTERVAL := '0 hours';
BEGIN
    -- Fetch check-in time
    SELECT MIN(Event_Time) INTO check_in_time
    FROM public.attendance_event
    WHERE Employee_ID = employee_id
    AND DATE(Event_Time) = day
    AND Event_Type = 'CheckIn'
    AND (mode_filter = 'All' OR Mode = mode_filter);
    
    -- Fetch check-out time
    SELECT MAX(Event_Time) INTO check_out_time
    FROM public.attendance_event
    WHERE Employee_ID = employee_id
    AND DATE(Event_Time) = day
    AND Event_Type = 'CheckOut'
    AND (mode_filter = 'All' OR Mode = mode_filter);
    
    -- Calculate working hours
    IF check_in_time IS NOT NULL AND check_out_time IS NOT NULL THEN
        total_time := check_out_time - check_in_time;
    END IF;
    
    RETURN total_time;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate weekly working hours
CREATE OR REPLACE FUNCTION calculate_weekly_working_hours(employee_id INT, year INT, week INT, mode_filter TEXT DEFAULT 'All')
RETURNS INTERVAL AS $$
DECLARE
    total_time INTERVAL := '0 hours';
    day_time INTERVAL;
BEGIN
    -- Loop through each day of the week and sum working hours
    FOR i IN 0..6 LOOP
        SELECT calculate_working_hours(employee_id, (DATE_TRUNC('week', TO_DATE(year || '-' || week, 'YYYY-IW')) + i)::DATE, mode_filter)
        INTO day_time;
        total_time := total_time + COALESCE(day_time, '0 hours');
    END LOOP;
    
    RETURN total_time;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate monthly working hours
CREATE OR REPLACE FUNCTION calculate_monthly_working_hours(employee_id INT, year INT, month INT, mode_filter TEXT DEFAULT 'All')
RETURNS INTERVAL AS $$
DECLARE
    total_time INTERVAL := '0 hours';
    day_time INTERVAL;
    start_date DATE := TO_DATE(year || '-' || month || '-01', 'YYYY-MM-DD');
    end_date DATE := (start_date + INTERVAL '1 month - 1 day')::DATE;
BEGIN
    -- Loop through each day of the month and sum working hours
    FOR i IN 0..(end_date - start_date) LOOP
        SELECT calculate_working_hours(employee_id, (start_date + i)::DATE, mode_filter)
        INTO day_time;
        total_time := total_time + COALESCE(day_time, '0 hours');
    END LOOP;
    
    RETURN total_time;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update the working_hours table after a checkout event
CREATE OR REPLACE FUNCTION update_working_hours() 
RETURNS TRIGGER AS $$
DECLARE
    day_working_hours INTERVAL;
    week_working_hours INTERVAL;
    month_working_hours INTERVAL;
    current_day DATE;
    current_week INT;
    current_month INT;
    current_year INT;
BEGIN
    IF (NEW.Event_Type = 'CheckOut') THEN
        -- Get day, week, month, year from the event timestamp
        current_day := DATE(NEW.Event_Time);
        current_week := EXTRACT(week FROM current_day);
        current_month := EXTRACT(month FROM current_day);
        current_year := EXTRACT(year FROM current_day);
        
        -- Calculate working hours for the current day
        SELECT calculate_working_hours(NEW.Employee_ID, current_day, NEW.Mode)
        INTO day_working_hours;
        
        -- Insert or update daily working hours
        INSERT INTO public.working_hours(Employee_ID, Day, Week, Month, Year, Mode, Total_Hours)
        VALUES (NEW.Employee_ID, current_day, current_week, current_month, current_year, NEW.Mode, day_working_hours)
        ON CONFLICT (Employee_ID, Day, Mode)
        DO UPDATE SET Total_Hours = EXCLUDED.Total_Hours;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger definition on the attendance_event table
CREATE TRIGGER after_checkout
AFTER INSERT ON public.attendance_event
FOR EACH ROW
WHEN (NEW.Event_Type = 'CheckOut')
EXECUTE FUNCTION update_working_hours();

-- Commit the transaction
COMMIT;


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Drop the table if it exists
DROP TABLE IF EXISTS employee_attendance CASCADE;
DROP TABLE IF EXISTS employee_offices CASCADE;
DROP TABLE IF EXISTS working_hours_data CASCADE;

-- Table for storing attendance events (geolocation/manual mode)
CREATE TABLE employee_attendance (
    attendance_id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    office_id TEXT,
    event_type TEXT CHECK (event_type IN ('checkin', 'checkout')),
    event_time TIMESTAMPTZ NOT NULL,
    mode TEXT CHECK (mode IN ('geolocation', 'manual')),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (office_id) REFERENCES offices(office_id)
);

-- Table to store employee and office mappings (editable by managers only)
CREATE TABLE employee_offices (
    employee_id INT NOT NULL,
    office_id TEXT NOT NULL,
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
