CREATE DATABASE WMS
USE WMS

CREATE TABLE Clients
(
ClientId INT PRIMARY KEY IDENTITY,
FirstName VARCHAR(50) NOT NULL,
LastName VARCHAR(50) NOT NULL,
Phone CHAR(12) NOT NULL
)

CREATE TABLE Mechanics
(
MechanicId INT PRIMARY KEY IDENTITY,
FirstName VARCHAR(50) NOT NULL,
LastName VARCHAR(50) NOT NULL,
[Address] VARCHAR(255) NOT NULL
)

CREATE TABLE Models
(
ModelId INT PRIMARY KEY IDENTITY,
[Name] VARCHAR(50) UNIQUE NOT NULL
)

CREATE TABLE Jobs
(
JobId INT PRIMARY KEY IDENTITY,
ModelId INT FOREIGN KEY REFERENCES Models(ModelId) NOT NULL,
[Status] VARCHAR(11) NOT NULL DEFAULT 'Pending' CHECK ([Status] IN ('Pending','In Progress','Finished')),
ClientId INT FOREIGN KEY REFERENCES Clients(ClientId) NOT NULL,
MechanicId INT FOREIGN KEY REFERENCES Mechanics(MechanicId),
IssueDate DATE NOT NULL,
FinishDate DATE
)

CREATE TABLE Orders
(
OrderId INT PRIMARY KEY IDENTITY,
JobId INT FOREIGN KEY REFERENCES Jobs(JobId) NOT NULL,
IssueDate DATE,
Delivered BIT DEFAULT 0 NOT NULL
)

CREATE TABLE Vendors
(
VendorId INT PRIMARY KEY IDENTITY,
[Name] VARCHAR(50) UNIQUE NOT NULL
)

CREATE TABLE Parts
(
PartId INT PRIMARY KEY IDENTITY,
SerialNumber VARCHAR(50) UNIQUE NOT NULL,
[Description] VARCHAR(255),
Price DECIMAL(6,2) CHECK(Price > 0) NOT NULL,
VendorId INT FOREIGN KEY REFERENCES Vendors(VendorId) NOT NULL,
StockQty INT CHECK(StockQty >=0) DEFAULT 0 NOT NULL
)

CREATE TABLE OrderParts
(
OrderId INT FOREIGN KEY REFERENCES Orders(OrderId),
PartId INT FOREIGN KEY REFERENCES Parts(PartId),
Quantity INT CHECK(Quantity > 0) DEFAULT 1 NOT NULL,
PRIMARY KEY(OrderId, PartId)
)

CREATE TABLE PartsNeeded
(
JobId INT FOREIGN KEY REFERENCES Jobs(JobId),
PartId INT FOREIGN KEY REFERENCES Parts(PartId),
Quantity INT CHECK(Quantity > 0) DEFAULT 1 NOT NULL,
PRIMARY KEY (JobId, PartId)
)


--2
INSERT INTO Clients
(FirstName, LastName, Phone)
VALUES
('Teri',	'Ennaco',	'570-889-5187'),
('Merlyn',	'Lawler',	'201-588-7810'),
('Georgene'	,'Montezuma'	,'925-615-5185'),
('Jettie',	'Mconnell',	'908-802-3564'),
('Lemuel',	'Latzke',	'631-748-6479'),
('Melodie',	'Knipp',	'805-690-1682'),
('Candida',	'Corbley',	'908-275-8357')

INSERT INTO Parts
(SerialNumber, Description, Price, VendorId)
VALUES
('WP8182119',	'Door Boot Seal',	117.86,	2),
('W10780048',	'Suspension Rod',	42.81,	1),
('W10841140',	'Silicone Adhesive', 	6.77,	4),
('WPY055980',	'High Temperature Adhesive',	13.94,	3)


--3


UPDATE Jobs
SET [Status] = 'In Progress',
	MechanicId = (SELECT 
					MechanicId
					FROM Mechanics
					WHERE FirstName = 'Ryan' AND LastName = 'Harnos')
	WHERE [Status] = 'Pending'

--4

DELETE FROM OrderParts
WHERE OrderId = 19

DELETE 
FROM Orders
WHERE OrderId = 19



--5
SELECT 
CONCAT(m.FirstName,' ', m.LastName) AS Mechanic,
j.Status,
j.IssueDate
FROM Mechanics AS m
JOIN Jobs AS j ON j.MechanicId = m.MechanicId
ORDER BY m.MechanicId, j.IssueDate

--6
SELECT 
	CONCAT(c.FirstName, ' ', c.LastName) AS Client,
	DATEDIFF(DAY, j.IssueDate, '2017-04-24') AS [Days going],
	j.Status
FROM Clients AS c
JOIN Jobs AS j ON c.ClientId = j.ClientId
WHERE j.Status <> 'Finished'
ORDER BY [Days going] DESC, c.ClientId

--7
SELECT 
	CONCAT(m.FirstName, ' ', m.LastName) AS Mechanic,
	AVG(DATEDIFF(DAY,IssueDate,FinishDate)) AS [Average Days]
FROM Mechanics AS m
JOIN Jobs AS j ON m.MechanicId = j.MechanicId
GROUP BY m.MechanicId, m.FirstName, m.LastName
ORDER BY m.MechanicId

--8

SELECT
	CONCAT(m.FirstName, ' ', m.LastName) AS Available
FROM Mechanics AS m
WHERE m.MechanicId NOT IN (SELECT 
								m.MechanicId
							FROM Mechanics AS m
							JOIN Jobs AS j ON j.MechanicId = m.MechanicId
							WHERE j.Status <> 'Finished'
							GROUP BY m.MechanicId)

USE WMS
--9
SELECT 
int.JobId,
SUM(int.cost) AS Total
FROM(SELECT 
	j.JobId,
	ISNULL(op.Quantity * p.Price,0) AS cost
FROM Jobs AS j
LEFT JOIN Orders AS o ON o.JobId = j.JobId
LEFT JOIN OrderParts AS op ON o.OrderId = op.OrderId
LEFT JOIN Parts AS p ON p.PartId = op.PartId
WHERE j.Status = 'Finished') AS int
GROUP BY int.JobId
ORDER BY Total DESC, JobId

--10


SELECT
	p.PartId,
	p.Description,
	SUM(pn.Quantity) AS [Required],
	SUM(p.StockQty) AS [In Stock],
	ISNULL(SUM(t.Quantity),0) AS Ordered
FROM Parts AS p
LEFT JOIN PartsNeeded AS pn ON p.PartId = pn.PartId
LEFT JOIN Jobs AS jn ON pn.JobId = jn.JobId
LEFT JOIN (SELECT 
				op.PartId,
				op.Quantity
			FROM OrderParts AS op 
			JOIN Orders AS o ON o.OrderId = op.OrderId
			WHERE o.Delivered = 0) AS t ON t.PartId = p.PartId
WHERE (jn.Status = 'In Progress')
GROUP BY p.PartId, p.Description
HAVING SUM(pn.Quantity) > SUM(p.StockQty) + ISNULL(SUM(t.Quantity),0)





--11

GO

CREATE PROCEDURE usp_PlaceOrder @jobID INT, @partSerialNumber VARCHAR(50), @quantity INT
AS
BEGIN
	BEGIN TRANSACTION
	IF @jobID NOT IN (SELECT JobId FROM Jobs)
	THROW 50011,'Job not found!',1

	IF @quantity <=0 
	THROW 50012, 'Part quantity must be more than zero!',1

	IF NOT EXISTS(SELECT *
					FROM Jobs 
					WHERE JobId = @jobID 
					AND Status <> 'Finished')
	THROW 50011, 'This job is not active!',1

		IF @partSerialNumber NOT IN (SELECT SerialNumber FROM Parts)
	THROW 50014,'Part not found!',1



	IF NOT EXISTS (SELECT 
							OrderId
						FROM Orders AS o
						JOIN Jobs AS j ON j.JobId = o.JobId
						WHERE j.JobId = @jobID
						--AND j.Status <> 'Finished'
						AND o.IssueDate IS NULL
						)
	BEGIN
		-- create new order
		INSERT INTO Orders (JobId, IssueDate, Delivered)
		VALUES
		(@jobID, NULL, 0)
	END
	
	DECLARE @orderId INT = (SELECT 
							OrderId
						FROM Orders AS o
						JOIN Jobs AS j ON j.JobId = o.JobId
						WHERE j.JobId = @jobID
						AND j.Status <> 'Finished'
						AND o.IssueDate IS NULL
						)
	
	

	DECLARE @partId INT = (SELECT PartId
							FROM Parts
							WHERE SerialNumber = @partSerialNumber)

	IF EXISTS (SELECT 
				*
				FROM OrderParts AS op
				WHERE OrderId = @orderId
				AND PartId = @partId)
	BEGIN
		UPDATE OrderParts
		SET Quantity += @quantity
		WHERE PartId = @partId 
		AND OrderId = @orderId
	END
	ELSE
	BEGIN
		INSERT INTO OrderParts
		(OrderId, PartId, Quantity)
		VALUES
		(@orderId, @partId, @quantity)
	END

			


	COMMIT
END

GO

--12

CREATE FUNCTION udf_GetCost(@jobID INT)
RETURNS DECIMAl(6,2)
AS
BEGIN
	RETURN (SELECT SUM(Price)
	FROM 
	(
		SELECT
			ISNULL(op.Quantity * p.Price,0) AS Price
		FROM Jobs AS j
		LEFT JOIN Orders AS o ON j.JobId = o.JobId
		LEFT JOIN OrderParts AS op ON o.OrderId = op.OrderId
		LEFT JOIN Parts AS p ON p.PartId = op.PartId
		WHERE j.JobId = @jobID

	)AS f)
END






