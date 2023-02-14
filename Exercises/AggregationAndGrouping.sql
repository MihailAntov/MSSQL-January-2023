--1

SELECT COUNT(*)
FROM WizzardDeposits

--3

SELECT MAX(MagicWandSize) AS LongestMagicWand
FROM WizzardDeposits


--3

SELECT 
	DepositGroup,
	MAX(MagicWandSize) AS LongestMagicWand
FROM WizzardDeposits
GROUP BY DepositGroup

--4
SELECT TOP(2) g.DepositGroup
FROM
(SELECT 
	DepositGroup,
	AVG(MagicWandSize) AS Size
FROM WizzardDeposits
GROUP BY DepositGroup) AS g
ORDER BY g.Size 

--5
SELECT 
	DepositGroup,
	SUM(DepositAmount)
FROM WizzardDeposits
GROUP BY DepositGroup

--6
SELECT 
	DepositGroup,
	SUM(DepositAmount)
FROM WizzardDeposits
WHERE MagicWandCreator = 'Ollivander family'
GROUP BY DepositGroup


--7

SELECT 
	DepositGroup,
	SUM(DepositAmount) AS Sum
FROM WizzardDeposits
WHERE MagicWandCreator = 'Ollivander family'
GROUP BY DepositGroup
HAVING SUM(DepositAmount) < 150000
ORDER BY Sum DESC

--8

SELECT 
	DepositGroup,
	MagicWandCreator,
	MIN(DepositCharge) AS MinDepositCharge
FROM WizzardDeposits
GROUP BY DepositGroup, MagicWandCreator
ORDER BY MagicWandCreator, DepositGroup

--9

SELECT
a.AgeGroup,
COUNT(a.AgeGroup)
FROM
(SELECT 
	CASE
		WHEN Age BETWEEN 0 AND 10 THEN '[0-10]'
		WHEN Age BETWEEN 11 AND 20 THEN '[11-20]'
		WHEN Age BETWEEN 21 AND 30 THEN '[21-30]'
		WHEN Age BETWEEN 31 AND 40 THEN '[31-40]'
		WHEN Age BETWEEN 41 AND 50 THEN '[41-50]'
		WHEN Age BETWEEN 51 AND 60 THEN '[51-60]'
		WHEN Age >= 61 THEN '[61+]'
	END	AS AgeGroup
FROM WizzardDeposits) AS a
GROUP BY a.AgeGroup

--10

SELECT
	SUBSTRING(FirstName,1,1) AS FirstLetter
FROM WizzardDeposits
WHERE DepositGroup = 'Troll Chest'
GROUP BY SUBSTRING(FirstName,1,1)

--11

SELECT
DepositGroup,
IsDepositExpired,
AVG(DepositInterest) AS AverageInterest
FROM WizzardDeposits
WHERE DepositStartDate > '1985-01-01'
GROUP BY DepositGroup, IsDepositExpired
ORDER BY DepositGroup DESC, IsDepositExpired

--12
SELECT 
	SUM(s.Difference)
FROM
(SELECT
	h.FirstName AS [Host Wizard],
	h.DepositAmount AS [Host Wizard Deposit],
	g.FirstName AS [Guest Wizard],
	g.DepositAmount AS [Guest Wizard Deposit],
	h.DepositAmount - g.DepositAmount AS [Difference]
FROM WizzardDeposits AS h
JOIN WizzardDeposits AS g
ON(h.Id = g.Id-1))AS s

--13

SELECT
	DepartmentID,
	SUM(Salary)
FROM Employees
GROUP BY DepartmentID
ORDER BY DepartmentID

--14
SELECT
	DepartmentID,
	MIN(Salary) AS [MinimumSalary]
FROM Employees
WHERE HireDate > '2000-01-01' AND DepartmentID IN (2,5,7)
GROUP BY DepartmentID

--15

SELECT 
	DepartmentID,
	AVG(f.NewSalary) AS AverageSalary
FROM
(SELECT 
	d.DepartmentId,
	CASE
		WHEN DepartmentID != 1 THEN Salary
		WHEN DepartmentID = 1 THEN Salary+5000
	END AS NewSalary
FROM (SELECT
		*
		FROM Employees
		WHERE Salary > 30000 AND (ManagerID != 42 OR ManagerID IS NULL)
      ) AS d) AS f
	  GROUP BY DepartmentID

--16
SELECT
	DepartmentID,
	MAX(Salary)
FROM Employees
GROUP BY DepartmentID
HAVING MAX(Salary) NOT BETWEEN 30000 AND 70000

--17
SELECT 
	COUNT (Salary)
FROM Employees
WHERE ManagerID IS NULL

--18
SELECT
	r.DepartmentID,
	r.Salary
FROM 
(SELECT DISTINCT
	DepartmentID,
	Salary,
	DENSE_RANK() OVER(PARTITION BY DepartmentID ORDER BY Salary DESC) AS Rank
FROM Employees) AS r
WHERE r.Rank = 3

--19

SELECT TOP(10)
	e.FirstName,
	e.LastName,
	e.DepartmentID
FROM Employees AS e
JOIN 
	(SELECT
		DepartmentID,
		AVG(Salary) AS AverageSalary
	FROM Employees 
	GROUP BY DepartmentID)
AS d
ON e.DepartmentID = d.DepartmentID
WHERE e.Salary > d.AverageSalary
ORDER BY DepartmentID