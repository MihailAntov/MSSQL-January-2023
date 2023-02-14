--1 

CREATE TABLE Logs
(
LogId INT IDENTITY(1,1) PRIMARY KEY,
AccountId INT FOREIGN KEY REFERENCES Accounts(Id),
OldSum DECIMAL(19,4),
NewSum DECIMAL(19,4)
)

GO



CREATE TRIGGER tr_AddToLogsOnAccountUpdate
ON Accounts FOR UPDATE
AS
BEGIN
	INSERT INTO Logs (AccountId, OldSum, NewSum)
	SELECT i.AccountHolderId, d.Balance, i.Balance
	FROM inserted AS i
	JOIN deleted AS d 
	ON i.Id = d.Id
	WHERE i.Balance <> d.Balance
END


--2
CREATE TABLE NotificationEmails
(
Id INT IDENTITY(1,1) PRIMARY KEY,
Recipient INT FOREIGN KEY REFERENCES Accounts(Id),
Subject VARCHAR(50),
Body VARCHAR(1000)
)


GO

CREATE TRIGGER tr_AddNotificationEmailOnLogAdded
ON Logs FOR INSERT
AS
BEGIN
	INSERT INTO NotificationEmails(Recipient,Subject,Body)
	SELECT 
	i.AccountId,
	CONCAT('Balance change for account: ',i.AccountId),
	CONCAT('On ',GETDATE(),' your balance was changed from ',i.OldSum,' to ',i.NewSum,'.')
	FROM inserted AS i
END

GO
--3


CREATE PROC usp_DepositMoney (@AccountId INT, @MoneyAmount DECIMAL(19,4))
AS 
BEGIN
	IF @MoneyAmount <= 0 
	BEGIN
		RETURN
	END

	UPDATE Accounts
	SET Balance = Balance + @MoneyAmount
	WHERE Id = @AccountId
END
--
EXEC usp_DepositMoney 1,10

SELECT *
FROM Accounts
WHERE Id = 1


--4
GO

CREATE PROC usp_WithdrawMoney (@AccountId INT, @MoneyAmount DECIMAL(19,4))
AS 
BEGIN
	IF @MoneyAmount <= 0 
	BEGIN
		RETURN
	END

	UPDATE Accounts
	SET Balance = Balance - @MoneyAmount
	WHERE Id = @AccountId
END

GO


--5
CREATE PROC usp_TransferMoney( @SenderId INT, @ReceiverId INT, @Amount DECIMAL(19,4))
AS
BEGIN
	EXEC usp_WithDrawMoney @senderId, @Amount
	EXEC usp_DepositMoney @ReceiverId, @Amount
END

--6


GO 


CREATE TRIGGER tr_RestrictBuyingItemWithHigherLevel
ON UserGameItems INSTEAD OF INSERT
AS
BEGIN
	INSERT INTO UserGameItems(ItemId, UserGameId)
	SELECT ins.ItemId, ins.UserGameId
			FROM inserted AS ins
			JOIN Items AS i 
			ON ins.ItemId = i.Id
			JOIN UsersGames AS ug
			ON ins.UserGameId = ug.Id
			WHERE i.MinLevel <= ug.Level

	
END



GO

CREATE OR ALTER TRIGGER tr_TakeCashOnAddedItem
ON UserGameItems FOR INSERT
AS
BEGIN

	
	
	
	UPDATE ug 
	SET ug.Cash =  ug.Cash - t.Total
	FROM inserted AS ins
	JOIN Items AS i
	ON i.Id = ins.ItemId
	JOIN UsersGames AS ug
	ON ug.Id = ins.UserGameId
	JOIN Users AS u 
	ON u.Id = ug.UserId
	JOIN (SELECT
		UserId,
		SUM(i.Price) AS total
	FROM inserted AS ins
	JOIN items AS i
	ON ins.ItemId = i.Id
	JOIN UsersGames AS ug
	ON ug.Id = ins.UserGameId
	GROUP BY ug.UserId) AS t
	ON t.UserId = u.Id
	
	
END

BEGIN TRANSACTION


UPDATE UsersGames
SET Cash += 50000
WHERE UserId IN (SELECT Id
				FROM Users
				WHERE Username IN ('baleremuda','loosenoise','inguinalself','buildingdeltoid','monoxidecos ')) 
  AND GameId IN (SELECT Id 
				FROM Games
				WHERE Name = 'Bali')

INSERT INTO UserGameItems
(
	ItemId, UserGameId
)
SELECT i.Id, ug.Id
FROM UsersGames AS ug
CROSS JOIN Items AS i
WHERE ug.GameId IN (SELECT Id FROM Games WHERE Name = 'Bali')
AND
(i.Id BETWEEN 251 AND 299 OR i.Id BETWEEN 501 AND 539)


SELECT 

u.Username, g.Name, ug.Cash, i.Name
FROM Users AS u
JOIN UsersGames AS ug
ON u.Id = ug.UserId
JOIN UserGameItems AS ugi
ON ugi.UserGameId = ug.Id
JOIN Games AS g
ON ug.GameId = g.Id
JOIN Items AS i
ON ugi.ItemId = i.Id
WHERE g.Name = 'Bali'
ORDER BY u.Username, i.Name






COMMIT

ROLLBACK

--7
--BEGIN TRANSACTION


DECLARE @stamatId INT = (SELECT
							Id
						FROM Users
						WHERE Username = 'Stamat')
DECLARE @safflowerId INT = (SELECT
							Id
						FROM Games
						WHERE Name = 'Safflower')
DECLARE @total MONEY
DECLARE @stamatCash MONEY

BEGIN TRANSACTION 
SET @total  = (SELECT 
						SUM(PRICE)
					FROM Items
					WHERE MinLevel BETWEEN 11 AND 12)

SET @stamatCash = (SELECT
										Cash
									FROM UsersGames
									WHERE GameId = @safflowerId AND UserId = @stamatId)


IF @total > @stamatCash
BEGIN
	ROLLBACK
END
ELSE
	BEGIN

		INSERT INTO [UserGameItems]
		(
			ItemId, UserGameId
		)
		SELECT i.Id, ug.Id
		FROM UsersGames AS ug
		CROSS JOIN Items AS i
		WHERE ug.GameId = @safflowerId
		AND ug.UserId = @stamatId
		AND i.MinLevel BETWEEN 11 AND 12

		UPDATE UsersGames
		SET Cash = Cash - @total
		WHERE UserId = @stamatId
		AND GameId = @safflowerId

		COMMIT
	END 

	

SET @total = (SELECT 
						SUM(PRICE)
					FROM Items
					WHERE MinLevel BETWEEN 19 AND 21)

SET @stamatCash =					(SELECT
										Cash
									FROM UsersGames
									WHERE UserId = @stamatId
									AND GameId = @safflowerId)
BEGIN TRANSACTION 

IF @total > @stamatCash
BEGIN
	ROLLBACK
END
ELSE
	BEGIN
		INSERT INTO [UserGameItems]
		(
			ItemId, UserGameId
		)
		SELECT i.Id, ug.Id
		FROM UsersGames AS ug
		CROSS JOIN Items AS i
		WHERE ug.GameId = @safflowerId
		AND ug.UserId = @stamatId
		AND i.MinLevel BETWEEN 19 AND 21

		UPDATE UsersGames
		SET Cash = Cash - @total
		WHERE UserId = @stamatId
		AND GameId = @safflowerId




		COMMIT
	END




SELECT i.Name AS 'Item Name'
FROM UserGameItems AS ugi
JOIN Items AS i
ON i.Id = ugi.ItemId
JOIN UsersGames AS ug
ON ugi.UserGameId = ug.Id
WHERE GameId = @safflowerId
AND UserId = @stamatId
ORDER BY i.[Name]





---------------------------------



--8
GO

CREATE PROC usp_AssignProject(@employeeId INT, @projectID INT) 
AS
BEGIN
	BEGIN TRANSACTION
	IF((SELECT COUNT(*) 
	FROM EmployeesProjects
	WHERE EmployeeID = @employeeId)>=3)
	BEGIN
		RAISERROR('The employee has too many projects!',16,1)
		ROLLBACK
	END
	ELSE
	BEGIN
		INSERT INTO EmployeesProjects
		VALUES (@employeeId, @projectID)
		COMMIT
	END
END

--9
CREATE TABLE Deleted_Employees
(
EmployeeId INT PRIMARY KEY,
FirstName VARCHAR(50),
LastName VARCHAR(50),
MiddleName VARCHAR(50),
JobTitle VARCHAR(50),
DepartmentId INT,
Salary DECIMAL(19,4)
)



CREATE TRIGGER tr_InsertIntoDeletedEmployees
ON Employees FOR DELETE
AS
BEGIN
	INSERT INTO Deleted_Employees (FirstName, LastName, MiddleName, JobTitle, DepartmentId, Salary)
	SELECT 	d.FirstName, 
			d.LastName,
			d.MiddleName,
			d.JobTitle,
			d.DepartmentID,
			d.Salary
	FROM deleted AS d

END


SELECT * FROM Employees
