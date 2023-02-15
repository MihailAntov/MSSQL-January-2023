--1

CREATE TABLE Users
(
Id INT PRIMARY KEY IDENTITY,
Username VARCHAR(30) UNIQUE NOT NULL,
Password VARCHAR(50) NOT NULL,
Name VARCHAR(50),
Birthdate DATETIME2,
Age INT CHECK(Age BETWEEN 14 AND 110),
Email VARCHAR(50) NOT NULL
)

CREATE TABLE Departments
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(50) NOT NULL
)

CREATE TABLE Employees
(
Id INT PRIMARY KEY IDENTITY,
FirstName VARCHAR(25),
LastName VARCHAR(25),
Birthdate DATETIME2,
Age INT CHECK(Age BETWEEN 18 AND 110),
DepartmentId INT FOREIGN KEY REFERENCES Departments(Id)
)

CREATE TABLE Categories
(
Id INT PRIMARY KEY IDENTITY,
Name VARCHAR(50) NOT NULL,
DepartmentId INT FOREIGN KEY REFERENCES Departments(Id) NOT NULL

)

CREATE TABLE Status
(
Id INT PRIMARY KEY IDENTITY,
Label VARCHAR(30) NOT NULL
)

CREATE TABLE Reports
(
Id INT PRIMARY KEY IDENTITY,
CategoryId INT FOREIGN KEY REFERENCES Categories(Id) NOT NULL,
StatusId INT FOREIGN KEY REFERENCES Status(Id) NOT NULL,
OpenDate DATETIME2 NOT NULL,
CloseDate DATETIME2,
Description VARCHAR(200) NOT NULL,
UserId INT FOREIGN KEY REFERENCES Users(Id) NOT NULL,
EmployeeId INT FOREIGN KEY REFERENCES Employees(Id)
)

--2 
INSERT INTO Employees
(FirstName, LastName, Birthdate, DepartmentId)
VALUES
('Marlo','O''Malley','1958-9-21',1),
('Niki','Stanaghan','1969-11-26',4),
('Ayrton','Senna','1960-03-21',9),
('Ronnie','Peterson','1944-02-14',9),
('Giovanna','Amati','1959-07-20',5)


INSERT INTO Reports
(CategoryId,StatusId, OpenDate, CloseDate, Description, UserId, EmployeeId)
VALUES
(1,	1,	'2017-04-13', NULL,			'Stuck Road on Str.133',			6,	2),
(6,	3,	'2015-09-05','2015-12-06',	'Charity trail running',			3,	5),
(14, 2,	'2015-09-07',NULL,			'Falling bricks on Str.58',			5,	2),
(4,	3,	'2017-07-03','2017-07-06',	'Cut off streetlight on Str.11',	1,	1)


--3
UPDATE Reports
SET CloseDate = GETDATE()
WHERE CloseDate IS NULL

--4

DELETE
FROM Reports
WHERE StatusId = 4

--5
SELECT
	Description, 
	FORMAT(OpenDate,'dd-MM-yyyy')
FROM Reports
WHERE EmployeeId IS NULL
ORDER BY OpenDate, Description

--6

SELECT
	r.Description, 
	c.Name
FROM Reports AS r
JOIN Categories AS c ON r.CategoryId = c.Id
ORDER BY r.Description, c.Name

--7

SELECT TOP(5)
	c.Name, 
	COUNT(r.Id) AS ReportsNumber
FROM Categories AS c
JOIN Reports AS r ON r.CategoryId = c.Id
GROUP BY c.Id, c.Name
ORDER BY ReportsNumber DESC, c.Name

--8

SELECT 
	u.Username,
	c.Name AS CategoryName
FROM Reports AS r
JOIN Users AS u ON r.UserId = u.Id
JOIN Categories AS c ON c.Id = r.CategoryId
WHERE DATEPART(MONTH, r.OpenDate) = DATEPART(MONTH, u.BirthDate)
AND DATEPART(DAY, r.OpenDate) = DATEPART(DAY, u.BirthDate)
ORDER BY u.Username, c.Name

--9

SELECT 
	CONCAT(e.FirstName,' ',e.LastName) AS FullName,
	COUNT (DISTINCT u.Id) AS UsersCount
FROM Employees AS e
LEFT JOIN Reports AS r ON e.Id = r.EmployeeId
LEFT JOIN Users AS u ON r.UserId = u.Id
GROUP BY e.FirstName, e.LastName
ORDER BY UsersCount DESC, FullName

--10

SELECT 
	ISNULL(e.FirstName+' '+e.LastName,'None') AS Employee,
	ISNULL(d.Name,'None') AS Department,
	ISNULL(c.Name,'None') AS Category,
	ISNULL(r.Description,'None') AS Description,
	ISNULL(FORMAT(r.OpenDate, 'dd.MM.yyy'),'None') AS OpenDate,
	ISNULL(s.Label,'None')AS Status,
	ISNULL(u.Name,'None')
FROM Reports AS r 
LEFT JOIN Employees AS e ON r.EmployeeId = e.Id
LEFT JOIN Departments AS d on e.DepartmentId = d.Id 
LEFT JOIN Categories AS c on r.CategoryId = c.Id
LEFT JOIN Status AS s ON r.StatusId = s.Id
LEFT JOIN Users AS u on r.UserId = u.Id
ORDER BY e.FirstName DESC, e.LastName DESC, d.Name, c.Name, r.Description, r.OpenDate,s.Label, u.Name


--11
GO

CREATE FUNCTION udf_HoursToComplete(@StartDate DATETIME, @EndDate DATETIME)
RETURNS INT
AS

BEGIN

	DECLARE @result INT

	IF @StartDate IS NULL 
	SET @result = 0
	ELSE IF @EndDate IS NULL
	SET @result = 0
	ELSE
	SET @result = DATEDIFF(HOUR, @StartDate,@EndDate)

	RETURN @Result
END

GO

--12

CREATE PROCEDURE usp_AssignEmployeeToReport @EmployeeId INT, @ReportId INT
AS 
BEGIN
	DECLARE @employeeDepartment INT = (SELECT
										DepartmentId
									FROM Employees
									WHERE Id = @EmployeeId)
	
	DECLARE @reportDepartment INT = (SELECT
										d.Id
									FROM Reports AS r
									JOIN Categories AS c ON r.CategoryId = c.Id
									JOIN Departments AS d ON c.DepartmentId = d.Id
									WHERE r.Id = @ReportId)

	IF (@employeeDepartment = @reportDepartment)
	BEGIN
		UPDATE Reports
		SET EmployeeId = @EmployeeId
		WHERE Id = @ReportId
	END
	ELSE
	THROW 50101,'Employee doesn''t belong to the appropriate department!',1
	

END