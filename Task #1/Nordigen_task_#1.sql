-- 1) Write CREATE TABLE statement for table EMPLOYEE based on sample data;
CREATE TABLE EMPLOYEE (
    employeeId INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    surname VARCHAR(100) NOT NULL,
    personalCode CHAR(12),
    startDate DATE
)
;

-- 2) Employee named Valentīna Konfekte (140200-22221) is starting next monday. Insert this information into EMPLOYEE table;
INSERT INTO EMPLOYEE (name, surname, personalCode, startDate) VALUES 
('Valentīna', 'Konfekte', '140200-22221', DATE_ADD(CURDATE(), INTERVAL (9 - DAYOFWEEK(CURDATE())) DAY));

-- 3) Calculate the average request (of traveling) count per employee since the policy has been introduced;
SELECT 
    COUNT(*)/(SELECT COUNT(*) FROM EMPLOYEE) AS average_request
FROM TRAVELS
;

-- 4) Calculate how often an employee got rejected for a request to work from elsewhere during up until now;
SELECT
    COUNT(*) * 100/(SELECT Count(*) FROM TRAVELS) AS frequency_rejection
FROM TRAVELS
WHERE process = 'rejected'
;    

-- 5) Calculate (what currently looks like) top 10 countries by all employees in year 2022;(note: “currently” as year is not yet over)
SELECT
    country,
    COUNT(*) AS count
FROM TRAVELS
GROUP BY country
ORDER BY count DESC
LIMIT 10
;

-- 6) Calculate average length of approved travel in each country;
SELECT
    country,
    AVG(DATEDIFF(endDate, startDate)) AS avg_len_app
FROM TRAVELS
WHERE process = 'approved'
GROUP BY country
;

-- 7) Find all employees who haven’t used the opportunity to work from another country and currently also haven’t requested any travel dates;
SELECT
    EMPLOYEE.employeeId,
    CONCAT(EMPLOYEE.name, ' ',EMPLOYEE.surname) AS full_name
FROM EMPLOYEE
LEFT JOIN TRAVELS
    ON EMPLOYEE.employeeId = TRAVELS.employeeId
WHERE TRAVELS.travelId IS NULL
;
    
-- 8) List all employees who have approved travel during the same time to the same destination;
SELECT
	CONCAT(EMPLOYEE.name, ' ',EMPLOYEE.surname) AS full_nam
FROM TRAVELS A, TRAVELS B
LEFT JOIN EMPLOYEE    
    ON EMPLOYEE.employeeId = B.employeeId
WHERE A.process = 'approved'
AND B.process = 'approved'
AND A.country = B.country
AND A.employeeId != B.employeeId
AND (A.endDate > B.startDate OR A.startDate < B.endDate)
;

-- 9) List each employee and their location on their birthday. If the birthday falls on a weekend, the value should be just “Weekend”.
-- Not working, but my approach was to convert personalcode to date and then use CASE WHEN to categorize whether birthday happens in weekend, during travel and return country and add ELSE to home if none of the above.
SELECT 
	CONCAT(SUBSTRING(personalCode, 1, 2), '-', SUBSTRING(personalCode, 3, 2), '-' , YEAR(CURDATE())) as bday, 
	CASE
		WHEN DAYOFWEEK(bday) IN (0,6) THEN 'Weekend'
		WHEN bday between startDate AND endDate THEN country
		ELSE 'Home'
	END AS bday_day
FROM EMPLOYEE
LEFT JOIN TRAVELS
	ON EMPLOYEE.employeeId = TRAVELS.employeeId
GROUP BY EMPLOYEE.employeeId
;

-- 10) List all employees with their preferred method of work - from the office, from home or work from another country.
SELECT
	EMPLOYEE.employeeId,
    CONCAT(EMPLOYEE.name, ' ',EMPLOYEE.surname) AS full_name,
    CASE
        WHEN COUNT(CASE WHEN ATTENDANCE.office = 0 THEN 1 END) > COUNT(CASE WHEN ATTENDANCE.office = 1 THEN 1 END) AND COUNT(CASE WHEN ATTENDANCE.office = 0 THEN 1 END) > SUM(CASE WHEN TRAVELS.process = 'approved' THEN DATEDIFF(TRAVELS.endDate, TRAVELS.startDate) ELSE 0 END) THEN 'Loving the home office'
        WHEN COUNT(CASE WHEN ATTENDANCE.office = 1 THEN 1 END) > COUNT(CASE WHEN ATTENDANCE.office = 0 THEN 1 END) AND COUNT(CASE WHEN ATTENDANCE.office = 1 THEN 1 END) > SUM(CASE WHEN TRAVELS.process = 'approved' THEN DATEDIFF(TRAVELS.endDate, TRAVELS.startDate) ELSE 0 END) THEN 'Digging the office vibe'
        WHEN SUM(CASE WHEN TRAVELS.process = 'approved' THEN DATEDIFF(TRAVELS.endDate, TRAVELS.startDate) ELSE 0 END) > COUNT(CASE WHEN ATTENDANCE.office = 0 THEN 1 END) AND SUM(CASE WHEN TRAVELS.process = 'approved' THEN DATEDIFF(TRAVELS.endDate, TRAVELS.startDate) ELSE 0 END) > COUNT(CASE WHEN ATTENDANCE.office = 1 THEN 1 END) THEN 'The world is my oyster'
        ELSE 'indecisive'
    END AS preferred_work_arrangement
FROM EMPLOYEE
LEFT JOIN TRAVELS    
    ON EMPLOYEE.employeeId = TRAVELS.employeeId
LEFT JOIN ATTENDANCE
    ON EMPLOYEE.employeeId = ATTENDANCE.employeeId
GROUP BY EMPLOYEE.employeeId
;