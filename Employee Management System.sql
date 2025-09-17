create database empdetails;

use empdetails;

-- Table 1: Job Department
CREATE TABLE JobDepartment (
    Job_ID INT PRIMARY KEY,
    jobdept VARCHAR(50),
    name VARCHAR(100),
    description TEXT,
    salaryrange VARCHAR(50)
);
-- Table 2: Salary/Bonus
CREATE TABLE SalaryBonus (
    salary_ID INT PRIMARY KEY,
    Job_ID INT,
    amount DECIMAL(10,2),
    annual DECIMAL(10,2),
    bonus DECIMAL(10,2),
    CONSTRAINT fk_salary_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(Job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);
-- Table 3: Employee
CREATE TABLE Employee (
    emp_ID INT PRIMARY KEY,
    firstname VARCHAR(50),
    lastname VARCHAR(50),
    gender VARCHAR(10),
    age INT,
    contact_add VARCHAR(100),
    emp_email VARCHAR(100) UNIQUE,
    emp_pass VARCHAR(50),
    Job_ID INT,
    CONSTRAINT fk_employee_job FOREIGN KEY (Job_ID)
        REFERENCES JobDepartment(Job_ID)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Table 4: Qualification
CREATE TABLE Qualification (
    QualID INT PRIMARY KEY,
    Emp_ID INT,
    Position VARCHAR(50),
    Requirements VARCHAR(255),
    Date_In DATE,
    CONSTRAINT fk_qualification_emp FOREIGN KEY (Emp_ID)
        REFERENCES Employee(emp_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Table 5: Leaves
CREATE TABLE Leaves (
    leave_ID INT PRIMARY KEY,
    emp_ID INT,
    date DATE,
    reason TEXT,
    CONSTRAINT fk_leave_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table 6: Payroll
CREATE TABLE Payroll (
    payroll_ID INT PRIMARY KEY,
    emp_ID INT,
    job_ID INT,
    salary_ID INT,
    leave_ID INT,
    date DATE,
    report TEXT,
    total_amount DECIMAL(10,2),
    CONSTRAINT fk_payroll_emp FOREIGN KEY (emp_ID) REFERENCES Employee(emp_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_job FOREIGN KEY (job_ID) REFERENCES JobDepartment(job_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_salary FOREIGN KEY (salary_ID) REFERENCES SalaryBonus(salary_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_payroll_leave FOREIGN KEY (leave_ID) REFERENCES Leaves(leave_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

select * from jobdepartment;

select * from salarybonus;

select * from employee;

select * from qualification;

select * from leaves;

select * from payroll;

/*Analysis Questions
1. EMPLOYEE INSIGHTS */
-- How many unique employees are currently in the system?
SELECT COUNT(DISTINCT emp_ID) as unique_emp_count FROM Employee;

-- Which departments have the highest number of employees?
SELECT jd.jobdept,COUNT(e.emp_ID) AS employee_count
FROM Employee e
JOIN JobDepartment jd ON e.Job_ID = jd.Job_ID
GROUP BY jd.jobdept
ORDER BY employee_count DESC;

-- What is the average salary per department?
SELECT 
    jd.JobDept AS Department,
    ROUND(AVG(sb.Annual),2) AS AverageSalary
FROM 
    JobDepartment jd
JOIN 
    SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY 
    jd.JobDept
ORDER BY 
    AverageSalary DESC;

-- Who are the top 5 highest-paid employees?
SELECT concat(firstname,' ', e.lastname) as emp_name, sb.Annual AS salary
FROM
    Employee e
JOIN
    SalaryBonus sb ON e.Job_ID = sb.Job_ID
ORDER BY
    salary DESC
LIMIT 5;

-- What is the total salary expenditure across the company?
SELECT
    SUM(sb.Annual) AS TotalSalaryExpenditure
FROM 
    Employee e
JOIN
    SalaryBonus sb ON e.Job_ID = sb.Job_ID;
    
    
-- 2. JOB ROLE AND DEPARTMENT ANALYSIS
-- How many different job roles exist in each department?
SELECT
    JobDept AS Department,
    COUNT(DISTINCT Name) AS NumberOfJobRoles
FROM
    JobDepartment
GROUP BY
    JobDept
ORDER BY
    NumberOfJobRoles DESC;
    
-- What is the average salary range per department?
SELECT
    jobdept AS Department,
    ROUND(AVG(
	(CAST(REPLACE(REPLACE(TRIM(SUBSTRING_INDEX(salaryrange, '-', 1)), '$', ''), ',', '') AS DECIMAL(10,2)) + 
	CAST(REPLACE(REPLACE(TRIM(SUBSTRING_INDEX(salaryrange, '-', -1)), '$', ''), ',', '') AS DECIMAL(10,2))
	) / 2
    ), 2) AS Average_Salary_Midpoint
FROM JobDepartment
WHERE salaryrange LIKE '%-%'
GROUP BY jobdept
ORDER BY Average_Salary_Midpoint DESC;
    
-- Which job roles offer the highest salary?
SELECT
    DENSE_RANK() OVER (ORDER BY sb.Annual DESC) AS SalaryRank,
    jd.Name AS JobRole,
    sb.Annual AS AnnualSalary
FROM
    JobDepartment jd
JOIN
    SalaryBonus sb ON jd.Job_ID = sb.Job_ID
LIMIT 5;
 
-- Which departments have the highest total salary allocation?
SELECT
    jd.JobDept AS Department,
    SUM(sb.Annual) AS TotalSalaryAllocation
FROM
    JobDepartment jd
JOIN
    SalaryBonus sb ON jd.Job_ID = sb.Job_ID
GROUP BY
    jd.JobDept
ORDER BY
    TotalSalaryAllocation DESC;

-- QUALIFICATION AND SKILLS ANALYSIS
-- How many employees have at least one qualification listed?
SELECT
    COUNT(DISTINCT q.Emp_ID) AS employees_with_qualifications
FROM
    Qualification q
WHERE
    TRIM(q.Requirements) != '';

-- Which positions require the most qualifications?
WITH QualificationRanks AS (
    SELECT Position,
        CASE
            WHEN Requirements LIKE '%PhD%' THEN 6
            WHEN Requirements LIKE '%PG%' OR Requirements LIKE '%M.Tech%' THEN 5
            WHEN Requirements LIKE '%MBA%' THEN 4
            WHEN Requirements LIKE '%B.Tech%' OR Requirements LIKE '%B.Sc%' OR Requirements LIKE 
            '%B.Com%' OR Requirements LIKE '%BCA%' OR Requirements LIKE '%BBA%' OR Requirements LIKE 
            '%B.Ed%' OR Requirements LIKE '%LLB%' THEN 3
            WHEN Requirements LIKE '%Diploma%' THEN 2
            ELSE 1
        END AS QualificationRank
    FROM Qualification)
SELECT Position, MAX(QualificationRank) as HighestRank
FROM QualificationRanks 
GROUP BY Position
ORDER BY HighestRank 
DESC LIMIT 10;


-- LEAVE AND ABSENCE PATTERNS
-- Which year had the most employees taking leaves?
SELECT
    YEAR(Date) AS LeaveYear,
    COUNT(DISTINCT Emp_ID) AS NumberOfEmployees
FROM
    Leaves
GROUP BY
    LeaveYear
ORDER BY
    NumberOfEmployees DESC;
    
-- What is the average number of leave days taken by its employees per department?
CREATE VIEW vw_AverageLeavePerDepartment AS
SELECT jd.jobdept AS department,
    ROUND(AVG(emp_leave_count.total_leaves), 2) AS avg_leave_days_per_employee
FROM ( 
    SELECT e.emp_ID, e.Job_ID, COUNT(l.leave_ID) AS total_leaves
    FROM Employee e 
    LEFT JOIN Leaves l ON e.emp_ID = l.emp_ID
    GROUP BY
        e.emp_ID, e.Job_ID
) AS emp_leave_count 
JOIN JobDepartment jd ON emp_leave_count.Job_ID = jd.Job_ID
GROUP BY jd.jobdept;
SELECT * FROM vw_AverageLeavePerDepartment;
    
-- Which employees have taken the most leaves?
SELECT 
    e.emp_ID,
    CONCAT(e.firstname, ' ', e.lastname) AS employee_name,
    COUNT(l.leave_ID) AS total_leaves
FROM 
    Employee e
JOIN 
    Leaves l ON e.emp_ID = l.emp_ID
GROUP BY 
    e.emp_ID
ORDER BY 
    total_leaves DESC;
    
-- What is the total number of leave days taken company-wide?
SELECT COUNT(*) AS total_leave_days FROM Leaves;

-- How do leave days correlate with payroll amounts?
WITH DepartmentGrossPay AS (
    SELECT
        jd.jobdept,
        SUM(sb.annual / 12 * 2) AS GrossPay_2Months
    FROM
        Employee e
    JOIN JobDepartment jd ON e.Job_ID = jd.Job_ID
    JOIN SalaryBonus sb ON e.Job_ID = sb.Job_ID
    GROUP BY
        jd.jobdept
),
DepartmentMetrics AS (
    SELECT
        jd.jobdept,
        SUM(p.total_amount) AS NetPay,
        COUNT(DISTINCT l.leave_ID) AS TotalLeaves
    FROM
        Employee e
    JOIN JobDepartment jd ON e.Job_ID = jd.Job_ID
    LEFT JOIN Payroll p ON e.emp_ID = p.emp_ID
    LEFT JOIN Leaves l ON e.emp_ID = l.emp_ID
    GROUP BY
        jd.jobdept
)
SELECT
    dgp.jobdept AS Department,
    dgp.GrossPay_2Months AS "Projected Gross Pay (2 Months)",
    dm.NetPay AS "Actual Net Pay (2 Months)",
    (dgp.GrossPay_2Months - dm.NetPay) AS "Total Deductions",
    dm.TotalLeaves AS "Total Leaves"
FROM
    DepartmentGrossPay dgp
JOIN
    DepartmentMetrics dm ON dgp.jobdept = dm.jobdept
ORDER BY
    "Total Deductions" DESC;     
     
     
     
     
-- PAYROLL AND COMPENSATION ANALYSIS
-- What is the total monthly payroll processed?
SELECT
    DATE_FORMAT(Date, '%Y-%m') AS PayrollMonth,
    SUM(total_amount) AS TotalMonthlyPayroll 
FROM
    Payroll
GROUP BY
    PayrollMonth;

  
-- What is the average bonus given per department?
SELECT
    jd.JobDept AS Department,
    round(avg(sb.Bonus),2) AS AverageBonus
FROM
    SalaryBonus sb
JOIN
    JobDepartment jd ON sb.Job_ID = jd.Job_ID
GROUP BY
    jd.JobDept
ORDER BY
    AverageBonus DESC;
    
-- Which department receives the highest total bonuses?
SELECT 
    jd.jobdept AS department,
    SUM(sb.bonus) AS total_bonus
FROM 
    SalaryBonus sb
JOIN 
    JobDepartment jd ON sb.Job_ID = jd.Job_ID
GROUP BY 
    jd.jobdept
ORDER BY 
    total_bonus DESC
LIMIT 1;

-- What is the average value of total_amount after considering leaves deductions?

Select avg(total_amount) as avg_salary from payroll;