-- RDBMS Lab Project - Case 2
-- Dermatology Clinic Management System
-- MySQL 8.0+ | Run the full script in MySQL Workbench.
-- It recreates the project tables and sample data.

CREATE DATABASE IF NOT EXISTS dermatology_clinic;
USE dermatology_clinic;

-- Start fresh if you are rerunning the project.
DROP VIEW IF EXISTS vw_appointment_details;
DROP VIEW IF EXISTS vw_treatment_details;
DROP VIEW IF EXISTS vw_patient_names;
DROP PROCEDURE IF EXISTS sp_appointment_report;
DROP PROCEDURE IF EXISTS sp_treatment_cursor_report;
DROP PROCEDURE IF EXISTS sp_add_treatment;
DROP FUNCTION IF EXISTS fn_appointment_total;
DROP TRIGGER IF EXISTS trg_appointment_date_check;
DROP TRIGGER IF EXISTS trg_treatment_cost_check;
DROP TABLE IF EXISTS Treatment;
DROP TABLE IF EXISTS Appointment;
DROP TABLE IF EXISTS Dermatologist;
DROP TABLE IF EXISTS Patient;

-- Tables and constraints from the ER diagram.
CREATE TABLE Patient (
    PatientID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DOB DATE NOT NULL,
    Phone VARCHAR(15) NULL,
    CHECK (DOB >= '1900-01-01')
);

CREATE TABLE Dermatologist (
    DoctorID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Specialization VARCHAR(100) NOT NULL DEFAULT 'General Dermatology',
    LicenseNo VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE Appointment (
    ApptID INT AUTO_INCREMENT PRIMARY KEY,
    `Date` DATE NOT NULL,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (DoctorID) REFERENCES Dermatologist(DoctorID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE Treatment (
    TreatID INT AUTO_INCREMENT PRIMARY KEY,
    Type VARCHAR(100) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    ApptID INT NOT NULL,
    CHECK (Cost >= 0),
    FOREIGN KEY (ApptID) REFERENCES Appointment(ApptID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Sample records for testing the queries.
INSERT INTO Patient (FirstName, LastName, DOB) VALUES
('Aarav','Sharma','2002-04-15'), ('Diya','Mehta','1999-11-22'),
('Rohan','Verma','2001-07-09'), ('Ananya','Singh','1998-02-18'),
('Kabir','Gupta','2003-09-30'), ('Ishita','Rao','2000-12-05'),
('Vivaan','Joshi','1997-06-12'), ('Meera','Kapoor','2002-01-25');

INSERT INTO Dermatologist (Name, Specialization, LicenseNo) VALUES
('Dr. Neha Malhotra','Clinical Dermatology','DERM-RJ-1001'),
('Dr. Arjun Bansal','Cosmetic Dermatology','DERM-RJ-1002'),
('Dr. Kavita Nair','Pediatric Dermatology','DERM-RJ-1003'),
('Dr. Rahul Sethi','Dermatologic Surgery','DERM-RJ-1004');

INSERT INTO Appointment (`Date`, PatientID, DoctorID) VALUES
('2026-09-02',1,1), ('2026-09-04',2,2), ('2026-09-08',3,1),
('2026-09-10',4,3), ('2026-09-12',5,2), ('2026-09-15',6,4),
('2026-09-18',7,1), ('2026-09-20',8,3), ('2026-09-22',1,2),
('2026-09-25',3,4);

INSERT INTO Treatment (Type, Cost, ApptID) VALUES
('Acne Consultation',800,1), ('Topical Medication',450,1),
('Chemical Peel',2200,2), ('Acne Consultation',800,3),
('Eczema Treatment',1200,4), ('Skin Analysis',600,5),
('Laser Therapy',3500,6), ('Follow-up Consultation',500,7),
('Pediatric Skin Consultation',900,8), ('Cosmetic Consultation',1000,9),
('Minor Skin Procedure',2800,10), ('Prescription Review',400,3);

-- ALTER TABLE and indexes.
ALTER TABLE Patient ALTER COLUMN Phone SET DEFAULT NULL;
CREATE INDEX idx_appointment_patient ON Appointment(PatientID);
CREATE INDEX idx_appointment_doctor_date ON Appointment(DoctorID, `Date`);
CREATE INDEX idx_treatment_appointment ON Treatment(ApptID);

-- Basic SELECT, filtering, sorting and aggregate functions.
SELECT PatientID, FirstName, LastName, DOB
FROM Patient WHERE DOB < '2002-01-01' ORDER BY DOB LIMIT 5;

SELECT * FROM Treatment
WHERE Cost >= 800 AND Cost < 3000 ORDER BY Cost DESC;

SELECT * FROM Patient
WHERE FirstName LIKE 'A%' OR LastName IN ('Mehta','Gupta');

SELECT DISTINCT Specialization FROM Dermatologist ORDER BY Specialization;

SELECT COUNT(*) AS TreatmentCount, SUM(Cost) AS TotalCost,
       AVG(Cost) AS AverageCost, MAX(Cost) AS HighestCost,
       MIN(Cost) AS LowestCost
FROM Treatment;

SELECT D.Name, COUNT(A.ApptID) AS AppointmentCount
FROM Dermatologist D JOIN Appointment A ON A.DoctorID = D.DoctorID
GROUP BY D.DoctorID, D.Name
HAVING COUNT(A.ApptID) >= 2
ORDER BY AppointmentCount DESC;

-- JOIN examples: inner/equi, left, cross, natural, self and non-equi.
SELECT A.ApptID, A.`Date`, CONCAT(P.FirstName,' ',P.LastName) AS PatientName,
       D.Name AS Dermatologist
FROM Appointment A
JOIN Patient P ON P.PatientID = A.PatientID
JOIN Dermatologist D ON D.DoctorID = A.DoctorID
ORDER BY A.`Date`;

SELECT A.ApptID, A.`Date`, T.Type, T.Cost
FROM Appointment A LEFT JOIN Treatment T ON T.ApptID = A.ApptID;

SELECT P.FirstName, D.Name AS Dermatologist
FROM Patient P CROSS JOIN Dermatologist D LIMIT 10;

SELECT PatientID, FirstName, LastName, ApptID, `Date`
FROM Patient NATURAL JOIN Appointment;

SELECT D1.Name AS DoctorOne, D2.Name AS DoctorTwo, D1.Specialization
FROM Dermatologist D1 JOIN Dermatologist D2
ON D1.Specialization = D2.Specialization AND D1.DoctorID < D2.DoctorID;

SELECT A1.ApptID AS EarlierAppointment, A2.ApptID AS LaterAppointment
FROM Appointment A1 JOIN Appointment A2 ON A1.`Date` < A2.`Date`
LIMIT 10;

-- Single-row, multiple-row and correlated subqueries.
SELECT Type, Cost FROM Treatment
WHERE Cost > (SELECT AVG(Cost) FROM Treatment);

SELECT PatientID, FirstName, LastName FROM Patient
WHERE PatientID IN (SELECT PatientID FROM Appointment);

SELECT A.ApptID, A.`Date`,
       (SELECT COALESCE(SUM(T.Cost),0) FROM Treatment T
        WHERE T.ApptID = A.ApptID) AS TreatmentTotal
FROM Appointment A;

-- Views for appointment and treatment reports.
CREATE VIEW vw_appointment_details AS
SELECT A.ApptID, A.`Date` AS AppointmentDate, P.PatientID,
       CONCAT(P.FirstName,' ',P.LastName) AS PatientName,
       D.DoctorID, D.Name AS DermatologistName, D.Specialization
FROM Appointment A
JOIN Patient P ON P.PatientID = A.PatientID
JOIN Dermatologist D ON D.DoctorID = A.DoctorID;

CREATE VIEW vw_treatment_details AS
SELECT T.TreatID, T.Type AS TreatmentType, T.Cost, T.ApptID,
       A.`Date` AS AppointmentDate,
       CONCAT(P.FirstName,' ',P.LastName) AS PatientName,
       D.Name AS DermatologistName
FROM Treatment T
JOIN Appointment A ON A.ApptID = T.ApptID
JOIN Patient P ON P.PatientID = A.PatientID
JOIN Dermatologist D ON D.DoctorID = A.DoctorID;

CREATE VIEW vw_patient_names AS
SELECT PatientID, FirstName, LastName, DOB FROM Patient;

SELECT * FROM vw_appointment_details;
SELECT * FROM vw_treatment_details;
SELECT * FROM vw_patient_names;

-- Trigger checks for appointment dates and treatment costs.
DELIMITER $$
CREATE TRIGGER trg_appointment_date_check
BEFORE INSERT ON Appointment FOR EACH ROW
BEGIN
    DECLARE v_dob DATE;
    SELECT DOB INTO v_dob FROM Patient WHERE PatientID = NEW.PatientID;
    IF NEW.`Date` < v_dob THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Appointment date cannot be before date of birth';
    END IF;
END$$

CREATE TRIGGER trg_treatment_cost_check
BEFORE INSERT ON Treatment FOR EACH ROW
BEGIN
    IF NEW.Cost < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Treatment cost cannot be negative';
    END IF;
END$$
DELIMITER ;

-- Function: total treatment cost for one appointment.
DELIMITER $$
CREATE FUNCTION fn_appointment_total(p_appt_id INT)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(12,2);
    SELECT COALESCE(SUM(Cost),0.00) INTO v_total
    FROM Treatment WHERE ApptID = p_appt_id;
    RETURN v_total;
END$$
DELIMITER ;

-- Procedure: show an appointment with its patient, doctor and treatments.
DELIMITER $$
CREATE PROCEDURE sp_appointment_report(IN p_appt_id INT)
BEGIN
    SELECT A.ApptID, A.`Date` AS AppointmentDate,
           CONCAT(P.FirstName,' ',P.LastName) AS PatientName,
           D.Name AS Dermatologist, D.Specialization,
           COUNT(T.TreatID) AS TreatmentCount,
           COALESCE(SUM(T.Cost),0.00) AS TotalCost
    FROM Appointment A
    JOIN Patient P ON P.PatientID = A.PatientID
    JOIN Dermatologist D ON D.DoctorID = A.DoctorID
    LEFT JOIN Treatment T ON T.ApptID = A.ApptID
    WHERE A.ApptID = p_appt_id
    GROUP BY A.ApptID, A.`Date`, P.FirstName, P.LastName,
             D.Name, D.Specialization;
END$$
DELIMITER ;

-- Cursor: list treatments and calculate their total for an appointment.
DELIMITER $$
CREATE PROCEDURE sp_treatment_cursor_report(IN p_appt_id INT)
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_type VARCHAR(100);
    DECLARE v_cost DECIMAL(10,2);
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_total DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_list TEXT DEFAULT '';

    DECLARE c_treatments CURSOR FOR
        SELECT Type, Cost FROM Treatment
        WHERE ApptID = p_appt_id ORDER BY TreatID;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN c_treatments;
    read_loop: LOOP
        FETCH c_treatments INTO v_type, v_cost;
        IF v_done = 1 THEN LEAVE read_loop; END IF;
        SET v_count = v_count + 1;
        SET v_total = v_total + v_cost;
        SET v_list = CONCAT(v_list, IF(v_list = '', '', '; '),
                            v_type, ' (', FORMAT(v_cost,2), ')');
    END LOOP;
    CLOSE c_treatments;

    SELECT p_appt_id AS AppointmentID, v_count AS TreatmentCount,
           IF(v_list = '', 'No treatments found', v_list) AS Treatments,
           v_total AS TotalCost;
END$$
DELIMITER ;

-- Procedure: add a treatment after checking its cost.
DELIMITER $$
CREATE PROCEDURE sp_add_treatment(
    IN p_type VARCHAR(100), IN p_cost DECIMAL(10,2), IN p_appt_id INT
)
BEGIN
    IF p_cost < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Treatment cost cannot be negative';
    END IF;
    INSERT INTO Treatment (Type, Cost, ApptID)
    VALUES (p_type, p_cost, p_appt_id);
    SELECT LAST_INSERT_ID() AS NewTreatmentID;
END$$
DELIMITER ;

-- Transaction control: the temporary change is rolled back.
START TRANSACTION;
UPDATE Patient SET LastName = 'TemporaryName' WHERE PatientID = 1;
SAVEPOINT patient_update_done;
SELECT PatientID, FirstName, LastName FROM Patient WHERE PatientID = 1;
ROLLBACK TO SAVEPOINT patient_update_done;
ROLLBACK;

-- User privileges (optional; requires permission to manage users).
-- CREATE USER 'clinic_reader'@'localhost' IDENTIFIED BY 'Choose_A_Strong_Password';
-- GRANT SELECT ON dermatology_clinic.* TO 'clinic_reader'@'localhost';
-- REVOKE SELECT ON dermatology_clinic.* FROM 'clinic_reader'@'localhost';

-- Run the stored programs and check the main objects.
CALL sp_appointment_report(1);
CALL sp_treatment_cursor_report(1);
SELECT fn_appointment_total(1) AS AppointmentTreatmentTotal;

SHOW TABLES;
SELECT COUNT(*) AS PatientCount FROM Patient;
SELECT COUNT(*) AS DermatologistCount FROM Dermatologist;
SELECT COUNT(*) AS AppointmentCount FROM Appointment;
SELECT COUNT(*) AS TreatmentCount FROM Treatment;
SHOW INDEX FROM Appointment;
SHOW TRIGGERS;

-- NoSQL is a separate database model, so it is covered in the report
-- as a short comparison rather than implemented in this MySQL script.
