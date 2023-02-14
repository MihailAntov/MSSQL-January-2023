
--1
CREATE PROC usp_GetEmployeesSalaryAbove35000
AS
BEGIN
	SELECT 
	FirstName,
	LastName
	FROM Employees
	WHERE Salary >=35000
END


--2
GO

CREATE PROC usp_GetEmployeesSalaryAboveNumber @SalaryThreshold MONEY
AS
BEGIN
	SELECT 
	FirstName,
	LastName
	FROM Employees
	WHERE Salary >= @SalaryThreshold
END

GO
--3

CREATE PROC usp_GetTownsStartingWith @start NVARCHAR(10)
AS
BEGIN
	SELECT 
	[Name]
	FROM Towns
	WHERE [Name] LIKE CONCAT(@start, '%')
END

GO

--4

CREATE PROC usp_GetEmployeesFromTown @townName NVARCHAR(15)
AS
BEGIN
	SELECT 
		FirstName,
		LastName
	FROM Employees AS e
	JOIN Addresses AS a
	ON e.AddressID = a.AddressID
	JOIN Towns AS t
	ON t.TownID = a.TownID
	WHERE t.Name = @townName
END

--5
GO 

CREATE FUNCTION
ufn_GetSalaryLevel(@salary DECIMAL(18,4))
RETURNS VARCHAR(10)
AS
BEGIN
	DECLARE @result VARCHAR(10) = 'Average'
	IF @salary < 30000 
	SET @result = 'Low'
	ELSE IF @salary > 50000
	SET @result = 'High'
	RETURN @result
END

GO

--6
CREATE PROC usp_EmployeesBySalaryLevel @salaryLevel VARCHAR(10)
AS
BEGIN
	SELECT
		FirstName,
		LastName
	FROM Employees
	WHERE dbo.ufn_GetSalaryLevel(Salary) = @salaryLevel
END

GO

--7

CREATE FUNCTION 
ufn_IsWordComprised(@setOfLetters VARCHAR(20), @word VARCHAR(20))
RETURNS BIT
AS
BEGIN
	DECLARE @result BIT = 1;
	DECLARE @counter INT = 1
	WHILE @counter <= LEN(@word)
	BEGIN
		IF @setOfLetters NOT LIKE CONCAT('%',SUBSTRING(@word, @counter, 1),'%')
		BEGIN
			SET @result = 0
			RETURN @result
		END
		SET @counter = @counter + 1
	END
	RETURN @result
END



GO




--8
CREATE PROC usp_DeleteEmployeesFromDepartment @departmentID INT
AS
BEGIN

	ALTER TABLE Departments
	ALTER COLUMN ManagerID INT NULL

	UPDATE Departments
	SET ManagerID = NULL
	WHERE ManagerID IN (SELECT EmployeeID FROM Employees WHERE DepartmentID = @departmentID)

	UPDATE Employees
	SET ManagerID = NULL
	WHERE ManagerID IN (SELECT EmployeeID FROM Employees WHERE DepartmentID = @departmentID)

	DELETE FROM EmployeesProjects
	WHERE EmployeeID IN (SELECT EmployeeID FROM Employees WHERE DepartmentID = @departmentID)

	DELETE FROM Employees
	WHERE DepartmentID = @departmentID

	DELETE FROM Departments
	WHERE DepartmentID = @departmentID

	SELECT 
		COUNT(*)
	FROM Employees
	WHERE DepartmentID = @departmentID


END

--9

CREATE PROC usp_GetHoldersFullName
AS
BEGIN
	SELECT
	CONCAT(FirstName,' ',LastName) AS [Full Name]
	FROM AccountHolders
END



--10
CREATE PROC usp_GetHoldersWithBalanceHigherThan @number MONEY
AS
BEGIN
	SELECT
	h.FirstName,
	h.LastName
	FROM AccountHolders AS h
	JOIN Accounts AS a
	ON(h.Id = a.AccountHolderId)
	GROUP BY h.Id, h.FirstName, h.LastName
	HAVING SUM(Balance) > @number
	ORDER BY h.FirstName, h.LastName
END


--11
GO

CREATE FUNCTION ufn_CalculateFutureValue(@sum MONEY, @rate FLOAT, @years INT)
RETURNS MONEY
AS
BEGIN
	DECLARE @result MONEY
	SET @result = @sum * POWER(1+@rate,@years)
	RETURN @result
END

--12
GO

CREATE PROC usp_CalculateFutureValueForAccount @id INT, @rate FLOAT
AS
BEGIN
	SELECT 
		a.Id AS [Account Id],
		h.FirstName AS [First Name],
		h.LastName AS [Last Name],
		a.Balance AS [Current Balance],
		dbo.ufn_CalculateFutureValue(a.Balance, @rate,5) AS [Balance in 5 years]
	FROM Accounts AS a
	JOIN AccountHolders AS h
	ON a.AccountHolderId = h.Id
	WHERE a.Id = @id
END

--13
GO

CREATE FUNCTION ufn_CashInUsersGames(@game VARCHAR(15))
RETURNS TABLE
AS
	RETURN

		SELECT 
		SUM(f.Cash) AS SumCash
		FROM
		(
			SELECT 
				ug.Cash AS Cash,
				ROW_NUMBER() OVER(ORDER BY ug.Cash DESC) AS Row
			FROM UsersGames AS ug
			JOIN Games AS g
			ON ug.GameId = g.Id
			WHERE g.Name = @game
		) AS f
		WHERE f.Row % 2 <> 0



		
		

