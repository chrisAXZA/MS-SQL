USE [Bank]

-- 19.
SELECT *
FROM [Accounts]

CREATE TABLE [Logs]
(
    [LogId] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    [AccountId] INT FOREIGN KEY REFERENCES [Accounts]([Id]),
    [OldSum] DECIMAL(15, 2),
    [NewSum] DECIMAL(15, 2),
)

GO
CREATE OR ALTER TRIGGER tr_test
ON [Accounts] AFTER UPDATE
AS
SELECT *
FROM inserted

SELECT *
FROM deleted
GO

-- UPDATE [Accounts]
-- SET [Balance] += 10
-- WHERE [Id] = 1

GO
CREATE OR ALTER TRIGGER tr_InsertAccountInfo
ON [Accounts] AFTER UPDATE
AS
DECLARE @newSum DECIMAL(15, 2) = (SELECT [Balance]
FROM inserted);
DECLARE @oldSum DECIMAL(15, 2) = (SELECT [Balance]
FROM deleted);
-- DECLARE @targetAccount INT = (SELECT [i].[Id]
-- FROM inserted AS [i] JOIN deleted AS [d] ON [d].[Id] = [i].[Id]
-- WHERE [i].[Balance] <> [d].[Balance])
DECLARE @accountId INT = (SELECT [Id]
FROM inserted) -- inserted or deleted can be used

INSERT INTO [Logs]
    ([AccountId], [OldSum], [NewSum])
VALUES
    -- (@targetAccount, @oldSum, @newSum)
    (@accountId, @oldSum, @newSum)
GO

-- 20.
CREATE TABLE [NotificationEmails]
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    [Recipient] INT FOREIGN KEY REFERENCES [Accounts]([Id]),
    [Subject] VARCHAR(50),
    [Body] VARCHAR(MAX),
)

GO
CREATE OR ALTER TRIGGER tr_LogEmail
ON [Logs] AFTER INSERT 
AS
DECLARE @accountID INT = (SELECT TOP(1)
    [AccountId]
FROM inserted);
-- TOP(1) to be save that only one recored is returned
DECLARE @subject VARCHAR(50) = CONCAT('Balance change for account: ', @accountID);
DECLARE @newSum DECIMAL(15, 2) = (SELECT TOP(1)
    [NewSum]
FROM inserted);
DECLARE @oldSum DECIMAL(15, 2) = (SELECT TOP(1)
    [OldSum]
FROM inserted);
DECLARE @body VARCHAR(MAX) = CONCAT('On ', GETDATE(), ' your balance was changed from ', @oldSum, ' to ', @newSum,'.');

INSERT INTO [NotificationEmails]
    ([Recipient], [Subject], [Body])
VALUES
    -- (@accountID, @subject, @body)
    (@accountID,
        'Balance change for account: ' + CAST(@accountID AS VARCHAR(20)),
        'On ' + CONVERT(VARCHAR(30), GETDATE(), 100) + ' your balance was changed from ' + CAST(@oldSum AS VARCHAR(20)) + ' to ' + CAST(@newSum AS VARCHAR(20)) + '.')
        -- Without CONCAT, CAST is required for succesfull concatination
GO

-- Target style for this exercise is 100 !!!
SELECT CONVERT(VARCHAR(30), GETDATE(), 100)

SELECT CAST(20 AS VARCHAR(20))

UPDATE [Accounts]
SET [Balance] += 100
WHERE [Id] = 1

-- 21.
GO
CREATE OR ALTER PROCEDURE usp_DepositMoney
    (@AccountId INT,
    @MoneyAmount DECIMAL(15, 4))
AS
BEGIN TRANSACTION
DECLARE @account INT = (SELECT [Id]
FROM [Accounts]
WHERE [Id] = @AccountId);

IF (@account IS NULL)
BEGIN
    ROLLBACK;
    RAISERROR('Invalid Account ID!', 16, 1);
    RETURN;
END

IF (@MoneyAmount < 0)
BEGIN
    ROLLBACK;
    RAISERROR('Money can not be negative!', 16, 1);
    RETURN;
END

UPDATE [Accounts]
SET [Balance] += @MoneyAmount
WHERE [Id] = @account

COMMIT TRANSACTION
GO

EXEC usp_DepositMoney 1, 246.88

SELECT *
FROM [Accounts]

-- 22.
GO
CREATE OR ALTER PROCEDURE usp_WithdrawMoney
    (@AccountId INT,
    @MoneyAmount DECIMAL(15, 4))
AS
BEGIN TRANSACTION
DECLARE @account INT = (SELECT [Id]
FROM [Accounts]
WHERE [Id] = @AccountId);

DECLARE @currentBalance DECIMAL(15, 4) = (SELECT [Balance]
FROM [Accounts]
WHERE [Id] = @AccountId);

IF (@account IS NULL)
BEGIN
    ROLLBACK;
    RAISERROR('Invalid account number!', 16, 1);
    RETURN;
END

IF (@MoneyAmount < 0)
BEGIN
    ROLLBACK;
    RAISERROR('Money amount can not be negative!', 16, 1);
    RETURN;
END

IF (@currentBalance < @MoneyAmount)
BEGIN
    ROLLBACK;
    RAISERROR('Not enough money on account!', 16, 1);
    RETURN;
END

UPDATE [Accounts]
SET [Balance] -= @MoneyAmount
WHERE [Id] = @account

COMMIT TRANSACTION
GO

-- 23.
GO
CREATE OR ALTER PROCEDURE usp_TransferMoney
    (@SenderId INT,
    @ReceiverId INT,
    @Amount DECIMAL(15, 4))
AS
BEGIN TRANSACTION
EXEC usp_WithdrawMoney @SenderId, @Amount;
EXEC usp_DepositMoney @ReceiverId, @Amount;

COMMIT TRANSACTION
GO

SELECT *
FROM [Accounts]
WHERE [Id] = 1 OR [Id] = 2

EXEC usp_TransferFund 1, 2, 100;

-- 25.
USE [Diablo]
-- EXEC sp_changedbowner 'target Name'

-- Task 1
SELECT *
FROM [Users] AS [U]
    JOIN [UsersGames] AS [UG]
    ON [UG].[UserId] = [U].[Id]
ORDER BY [UG].[Id] ASC

GO
CREATE OR ALTER TRIGGER tr_MinLevelItemsCheck
ON [UserGameItems] INSTEAD OF INSERT
-- INSTEAD OF INSERT is required since when case is invalid
-- no action is to be undertaken, otherwise Insert will be
-- executed
-- (@UserId INT, @ItemId INT)
AS
-- TOP(1) to ensure that only one values is returned !!!
-- only from inserted, from the other tables no risk !!!
DECLARE @itemId INT = (SELECT TOP(1) [ItemId]
FROM inserted);
DECLARE @userGameId INT = (SELECT TOP(1) [UserGameId]
FROM inserted);
DECLARE @itemLevel INT = (SELECT TOP(1) [MinLevel]
FROM [Items]
WHERE [Id] = @itemId);
DECLARE @userGameLevel INT = (SELECT TOP(1) [Level]
FROM [UsersGames]
WHERE [Id] = @userGameId);

IF (@userGameLevel >= @itemLevel)
BEGIN
    INSERT INTO [UserGameItems]
        ([ItemId], [UserGameId])
    VALUES
        (@itemId, @userGameId)
END
-- ELSE
-- BEGIN
    -- ROLLBACK;
    -- THROW 50001, 'Item level too high', 1;
    -- RAISERROR('Item level too high', 16, 1);
-- END
GO

SELECT *
FROM [UserGameItems]
WHERE [UserGameId] = 38

-- Should be stopped by trigger since item-level is higher
-- than user-level
-- INSERT INTO [UserGameItems]
--     ([ItemId], [UserGameId])
-- VALUES
--     (2, 38)
--     (2, 14) -- passes as item level is low enough for given user

-- Task 2

-- Different variants
SELECT [U].[Username]
FROM [UsersGames] AS [UG]
    JOIN [Users] AS [U]
    ON [U].[Id] = [UG].[UserId]
WHERE [GameId] IN
(SELECT [Id]
FROM [Games]
WHERE [Name] = 'Bali')

SELECT *
FROM [Users] AS [U]
    JOIN [UsersGames] AS [UG]
    ON [UG].[UserId] = [U].[Id]
    JOIN [Games] AS [G]
    ON [G].[Id] = [UG].[GameId]
-- ON [G].[Name] = 'Bali'
WHERE [G].[Name] = 'Bali'
    AND [U].[Username] IN 
    ('baleremuda', 
    'loosenoise', 
    'inguinalself', 
    'buildingdeltoid', 
    'monoxidecos')

-- Excute 50000+
UPDATE [UsersGames]
SET [Cash] += 50000
WHERE [GameId] IN (SELECT [Id]
    FROM [Games]
    WHERE [Name] = 'Bali')
    AND [UserId] IN (SELECT [Id]
    FROM [Users]
    WHERE [Username] IN ('baleremuda', 
    'loosenoise', 
    'inguinalself', 
    'buildingdeltoid', 
    'monoxidecos'))
-- WHERE [UserId] IN (SELECT [UG].[UserId]
-- FROM [Users] AS [U]
--     JOIN [UsersGames] AS [UG]
--     ON [UG].[UserId] = [U].[Id]
--     JOIN [Games] AS [G]
--     ON [G].[Id] = [UG].[GameId]
-- -- ON [G].[Name] = 'Bali'
-- WHERE [G].[Name] = 'Bali'
--     AND [U].[Username] IN 
-- ('baleremuda', 
-- 'loosenoise', 
-- 'inguinalself', 
-- 'buildingdeltoid', 
-- 'monoxidecos'))

-- Task 3, SP to be used since multiple operations are executed
SELECT *
FROM [Items]
WHERE [Id] BETWEEN 251 AND 299
    OR [Id] BETWEEN 501 AND 539
ORDER BY [Id]

GO
CREATE OR ALTER PROCEDURE usp_BuyItems
    (@UserId INT,
    @ItemId INT,
    @GameId INT)
AS
BEGIN TRANSACTION
DECLARE @user INT = (SELECT [Id]
FROM [Users]
WHERE [Id] = @UserId);
DECLARE @item INT = (SELECT [Id]
FROM [Items]
WHERE [Id] = @ItemId);

IF (@user IS NULL OR @item IS NULL)
    BEGIN
    ROLLBACK;
    RAISERROR('Invalid user/item Id!', 16, 1);
    RETURN;
END

DECLARE @userCash DECIMAL(15, 2) = (SELECT [Cash]
FROM [UsersGames]
WHERE [GameId] = @GameId
    -- WHERE [GameId] = 212
    -- (SELECT [Id]
    --     FROM [Games]
    -- WHERE [Name] = 'Bali')
    AND [UserId] = @UserId);
DECLARE @itemPrice DECIMAL(15, 2) = (SELECT [Price]
FROM [Items]
WHERE [Id] = @ItemId);

IF (@userCash - @itemPrice < 0)
BEGIN
    ROLLBACK;
    RAISERROR('Insufficient cash for item!', 16, 1);
    RETURN;
END

UPDATE [UsersGames]
SET [Cash] -= @itemPrice
WHERE [UserId] = @UserId
    AND [GameId] = @GameId
-- AND [GameId] = 212

DECLARE @userGameID INT = (SELECT [Id]
FROM [UsersGames]
WHERE [Userid] = @UserId AND [GameId] = @GameId)
-- WHERE [Userid] = @UserId AND [GameId] = 212)

INSERT INTO [UserGameItems]
    ([ItemId], [UserGameId])
VALUES
    (@ItemId, @userGameID)
-- (@ItemId, 212) in Demo, wrong value not ID of Game is needed
-- but Id of UsersGames

COMMIT TRANSACTION
GO

SELECT *
FROM [UsersGames]
ORDER BY [Id]

-- Buying multiple itmes

DECLARE @itemId INT = 251;
DECLARE @counterStop INT = 299;

WHILE (@itemId <= @counterStop)
BEGIN

    EXEC usp_BuyItems 12, @itemId, 212;
    EXEC usp_BuyItems 22, @itemId, 212;
    EXEC usp_BuyItems 37, @itemId, 212;
    EXEC usp_BuyItems 52, @itemId, 212;
    EXEC usp_BuyItems 61, @itemId, 212;

    SET @itemId += 1;
END

DECLARE @itemId2 INT = 501;
DECLARE @counterStop2 INT = 539;

WHILE (@itemId2 <= @counterStop2)
BEGIN

    EXEC usp_BuyItems 12, @itemId2, 212;
    EXEC usp_BuyItems 22, @itemId2, 212;
    EXEC usp_BuyItems 37, @itemId2, 212;
    EXEC usp_BuyItems 52, @itemId2, 212;
    EXEC usp_BuyItems 61, @itemId2, 212;

    SET @itemId2 += 1;
END

--
SELECT [Id]
FROM [Users]
WHERE [Username] IN ('baleremuda', 
    'loosenoise', 
    'inguinalself', 
    'buildingdeltoid', 
    'monoxidecos')

-- TASK 4
SELECT
    [U].[Username],
    [G].[Name],
    [UG].[Cash],
    [I].[Name]
FROM [UsersGames] AS [UG]
    JOIN [UserGameItems] AS [UGI]
    ON [UGI].[UserGameId] = [UG].[Id]
    JOIN [Items] AS [I]
    ON [I].[Id] = [UGI].[ItemId]
    JOIN [Users] AS [U]
    ON [U].[Id] = [UG].[UserId]
    JOIN [Games] AS [G]
    ON [G].[Id] = [UG].[GameId]
WHERE [G].[Name] = 'Bali'
ORDER BY [U].[Username] ASC, [I].[Name] ASC

-- DEMO
SELECT
    [U].[Username],
    [G].[Name],
    [UG].[Cash],
    [I].[Name]
FROM [Users] AS [U]
    JOIN [UsersGames] AS [UG]
    ON [UG].[UserId] = [U].[Id]
    JOIN [Games] AS [G]
    ON [G].[Id] = [UG].[GameId]
    -- ON [G].[Id] = [UG].[Id]
    JOIN [UserGameItems] AS [UGI]
    ON [UGI].[UserGameId] = [UG].[Id]
    JOIN [Items] AS [I]
    ON [I].[Id] = [UGI].[ItemId]
WHERE [G].[Name] = 'Bali'
ORDER BY [U].[Username] ASC, [I].[Name] ASC

-- 26.

-- STAMAT id = 9
-- SAFFLOWER id = 87
SELECT *
FROM [Users]
WHERE [Username] = 'Stamat'

SELECT *
FROM [UsersGames]

SELECT *
FROM [Items]

SELECT *
FROM [UserGameItems]

DECLARE @userGameID INT = (SELECT [Id]
FROM [UsersGames]
WHERE [UserId] = 9 AND [GameId] = 87);

-- SELECT [Id], @userGameID
-- FROM [Items]
-- WHERE [MinLevel] BETWEEN 11 AND 12

DECLARE @stamatCash DECIMAL(15, 2) = (SELECT [Cash]
FROM [UsersGames]
WHERE [Id] = @userGameID);
-- WHERE [GameId] = @userGameID); -- ERROR Id not GameId !!!

-- (SELECT [Cash]
-- FROM [UsersGames]
-- WHERE [UserId] = 9
--     AND [GameId] = (SELECT [Id]
--     FROM [Games]
--     WHERE [Name] = 'Safflower'))

DECLARE @totalPriceItems1 DECIMAL(15, 2) =
(SELECT SUM([Price]) AS [TotalPrice]
FROM [Items]
WHERE [MinLevel] BETWEEN 11 AND 12);

IF (@stamatCash >= @totalPriceItems1)
BEGIN
    BEGIN TRANSACTION
    UPDATE [UsersGames]
    SET [Cash] -= @totalPriceItems1
    WHERE [Id] = @userGameID -- ERROR JUDGE
    -- WHERE [GameId] = @userGameID
    -- WHERE [UserId] = 9
    --     AND [GameId] = 87

    INSERT INTO [UserGameItems]
        ([ItemId], [UserGameId])
    SELECT [Id], @userGameID
    FROM [Items]
    WHERE [MinLevel] BETWEEN 11 AND 12
    -- Select can also work with declared variable

    -- VALUES
    --     (16, 9), -- Error, not UserId but UserGameId which is 110 !!!
    --     (45, 110),
    --     (108, 110),
    --     (111, 110),
    --     (176, 110),
    --     (184, 110),
    --     (191, 110),
    --     (194, 110),
    --     (195, 110),
    --     (247, 110),
    --     (280, 110),
    --     (475, 110),
    --     (500, 110),
    --     (552, 110)

    COMMIT TRANSACTION
END

-- DECLARE @stamatCash2 DECIMAL(15, 2) = (SELECT [Cash]
SET @stamatCash = (SELECT [Cash]
FROM [UsersGames]
WHERE [Id] = @userGameID); -- ERROR Id not GameId
-- WHERE [GameId] = @userGameID);

DECLARE @totalPriceItems2 DECIMAL(15, 2) =
(SELECT SUM([Price]) AS [TotalPrice]
FROM [Items]
WHERE [MinLevel] BETWEEN 19 AND 21);

IF (@stamatCash >= @totalPriceItems2)
BEGIN
    BEGIN TRANSACTION
    UPDATE [UsersGames]
    SET [Cash] -= @totalPriceItems2
        WHERE [Id] = @userGameID -- ERROR JUDGE
    -- WHERE [GameId] = @userGameID

    INSERT INTO [UserGameItems]
        ([ItemId], [UserGameId])
    SELECT [Id], @userGameID
    FROM [Items]
    WHERE [MinLevel] BETWEEN 19 AND 21

    COMMIT TRANSACTION
END
-- Else not required for judge
-- ELSE
-- BEGIN
--     ROLLBACK;
--     RAISERROR('Not enough money to buy items!', 16, 1);
--     RETURN;
-- END

SELECT *
FROM [Items]
WHERE [MinLevel] BETWEEN 11 AND 12

-- SELECT *
-- FROM [Items]
-- WHERE [Id] BETWEEN 19 AND 21
--     OR [Id] BETWEEN 11 AND 12

-- SELECT [Id]
-- FROM [Items]
-- WHERE [MinLevel] BETWEEN 19 AND 21
--     OR [MinLevel] BETWEEN 11 AND 12

EXEC usp_BuyItems 9, 0, 87
-- Repeat 33 times for all of the relevant items

-- 33 items, one way is to group them into two and sum up their total value
-- and subtract the whole sums two times
-- SET @itemsCost = (SELECT SUM(Price) FROM Items WHERE MinLevel BETWEEN @minLevel AND @maxLevel);

--  Check if correct
-- SELECT
--     [I].[Name]
-- FROM [Users] AS [U]
--     JOIN [UsersGames] AS [UG]
--     ON [UG].[UserId] = [U].[Id]
--     JOIN [Games] AS [G]
--     ON [G].[Id] = [UG].[GameId]
--     JOIN [UserGameItems] AS [UGI]
--     ON [UGI].[UserGameId] = [UG].[GameId] -- CAREFULL [UG].[Id]
--     JOIN [Items] AS [I]
--     ON [I].[Id] = [UGI].[ItemId]
-- WHERE [U].[Username] = 'Stamat'
--     AND [G].[Name] = 'Safflower'
-- ORDER BY [I].[Name] ASC

SELECT
    [I].[Name] AS [Item Name]
FROM [Users] AS [U]
    JOIN [UsersGames] AS [UG] ON [UG].[UserId] = [U].[Id]
    JOIN [Games] AS [G] ON [G].[Id] = [UG].[GameId]
    JOIN [UserGameItems] AS [UGI] ON [UGI].[UserGameId] = [UG].[Id]
    JOIN [Items] AS [I] ON [I].[Id] = [UGI].[ItemId]
WHERE [U].[Username] = 'Stamat'
    AND [G].[Name] = 'Safflower'
ORDER BY [I].[Name] ASC

-- + + + + + + + + + + + + +
-- FINAL JUDGE

-- DECLARE @userGameID INT = (SELECT [Id]
-- FROM [UsersGames]
-- WHERE [UserId] = 9 AND [GameId] = 87);

-- DECLARE @stamatCash DECIMAL(15, 2) = (SELECT [Cash]
-- FROM [UsersGames]
-- WHERE [Id] = @userGameID); 

-- DECLARE @totalPriceItems1 DECIMAL(15, 2) =
-- (SELECT SUM([Price]) AS [TotalPrice]
-- FROM [Items]
-- WHERE [MinLevel] BETWEEN 11 AND 12);

-- IF (@stamatCash >= @totalPriceItems1)
-- BEGIN
--     BEGIN TRANSACTION
--     UPDATE [UsersGames]
--     SET [Cash] -= @totalPriceItems1
--     WHERE [Id] = @userGameID

--     INSERT INTO [UserGameItems]
--         ([ItemId], [UserGameId])
--     SELECT [Id], @userGameID
--     FROM [Items]
--     WHERE [MinLevel] BETWEEN 11 AND 12

--     COMMIT TRANSACTION
-- END

-- SET @stamatCash = (SELECT [Cash]
-- FROM [UsersGames]
-- WHERE [Id] = @userGameID);

-- SET @totalPriceItems1 =
-- (SELECT SUM([Price]) AS [TotalPrice]
-- FROM [Items]
-- WHERE [MinLevel] BETWEEN 19 AND 21);

-- IF (@stamatCash >= @totalPriceItems1)
-- BEGIN
--     BEGIN TRANSACTION
--     UPDATE [UsersGames]
--     SET [Cash] -= @totalPriceItems1
--     WHERE [Id] = @userGameID

--     INSERT INTO [UserGameItems]
--         ([ItemId], [UserGameId])
--     SELECT [Id], @userGameID
--     FROM [Items]
--     WHERE [MinLevel] BETWEEN 19 AND 21

--     COMMIT TRANSACTION
-- END

-- SELECT
--     [I].[Name] AS [Item Name]
-- FROM [Users] AS [U]
--     JOIN [UsersGames] AS [UG] ON [UG].[UserId] = [U].[Id]
--     JOIN [Games] AS [G] ON [G].[Id] = [UG].[GameId]
--     JOIN [UserGameItems] AS [UGI] ON [UGI].[UserGameId] = [UG].[Id]
--     JOIN [Items] AS [I] ON [I].[Id] = [UGI].[ItemId]
-- WHERE [U].[Username] = 'Stamat'
--     AND [G].[Name] = 'Safflower'
-- ORDER BY [I].[Name] ASC


-- 28.
USE [SoftUni]

GO
-- FOR JUDGE NEEDS TRANSACTION IN ORDER TO PASS!!!
CREATE OR ALTER PROCEDURE usp_AssignProject
    (@employeeId INT,
    @projectID INT)
AS
BEGIN
    DECLARE @emp INT = (SELECT [EmployeeID]
    FROM [Employees]
    WHERE [EmployeeID] = @employeeId);
    DECLARE @project INT = (SELECT [ProjectID]
    FROM [Projects]
    WHERE [ProjectID] = @projectID);

    IF (@emp IS NULL OR @project IS NULL)
    BEGIN
        ROLLBACK;
        RAISERROR('Invalid employee/project ID!', 16, 1);
        RETURN;
    END

    DECLARE @count INT = (SELECT COUNT(*)
    FROM [EmployeesProjects]
    WHERE [EmployeeID] = @emp);

    IF (@count >= 3)
    BEGIN
        ROLLBACK;
        RAISERROR('The employee has too many projects!', 16, 1);
        RETURN;
    END

    INSERT INTO [EmployeesProjects]
        ([EmployeeID], [ProjectID])
    VALUES
        (@emp, @project)

END
GO


-- DEMO
GO
CREATE OR ALTER PROCEDURE usp_AssignProject
    (@employeeId INT,
    @projectID INT)
AS
BEGIN TRANSACTION
DECLARE @employee INT = (SELECT [EmployeeID]
FROM [Employees]
WHERE [EmployeeID] = @employeeID);

DECLARE @project INT = (SELECT [ProjectID]
FROM [Projects]
WHERE [ProjectID] = @projectID);

IF (@projectID IS NULL OR @employee IS NULL)
BEGIN
    ROLLBACK;
    RAISERROR('Invalid project/employee ID!', 16, 1);
    RETURN;
END

DECLARE @employeeProjects INT = (SELECT COUNT(*)
FROM [EmployeesProjects]
WHERE [EmployeeID] = @employeeID);

IF (@employeeProjects >= 3)
BEGIN
    ROLLBACK;
    RAISERROR('The employee has too many projects!', 16, 1);
    -- 2?
    -- or 16, 2
    -- Sometimes judge requires state 2 !!!
    RETURN;
END

INSERT INTO [EmployeesProjects]
    ([EmployeeID], [ProjectID])
VALUES
    (@employeeId, @projectID)

COMMIT TRANSACTION
GO

SELECT *
FROM [EmployeesProjects]
WHERE [EmployeeID] = 1

EXEC usp_AssignProject 1, 8
-- should throw error since Employee already has 4 projects

EXEC usp_AssignProject 2, 1
-- has no projects, thus will pass

-- 29.
-- CREATE TABLE [Deleted_Employees]
-- (
--     [EmployeeId] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
--     [FirstName] VARCHAR(50) NOT NULL,
--     [LastName] VARCHAR(50) NOT NULL,
--     [MiddleName] VARCHAR(50) NULL,
--     [JobTitle] VARCHAR(50) NOT NULL,
--     [DepartmentId] INT FOREIGN KEY REFERENCES [Departments]([DepartmentId]) NOT NULL,
--     [Salary] MONEY NOT NULL
-- )

CREATE TABLE [Deleted_Employees]
(
    [EmployeeId] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    [FirstName] VARCHAR(50),
    [LastName] VARCHAR(50),
    [MiddleName] VARCHAR(50),
    [JobTitle] VARCHAR(50),
    [DepartmentId] INT,
    [Salary] DECIMAL(15, 2)
)

-- FOR JUDGE Submit only TRIGGER
GO
CREATE OR ALTER TRIGGER tr_EmployeeDeleted
ON [Employees] AFTER DELETE
AS
SET NOCOUNT ON
-- DECLARE @employeeID INT = (SELECT [EmployeeID]
-- FROM deleted); -- IDENTITY NOT NEEDED !!!

-- DECLARE @firstName VARCHAR(50) = (SELECT [FirstName]
-- FROM deleted);
-- DECLARE @middleName VARCHAR(50) = (SELECT [MiddleName]
-- FROM deleted);
-- DECLARE @lastName VARCHAR(50) = (SELECT [LastName]
-- FROM deleted);
-- DECLARE @jobTitle VARCHAR(50) = (SELECT [JobTitle]
-- FROM deleted);
-- DECLARE @departmentId INT = (SELECT [DepartmentID]
-- FROM deleted);
-- DECLARE @salary MONEY = (SELECT [Salary]
-- FROM deleted);
-- variables NOT NEEDED !!!

INSERT INTO [Deleted_Employees]
    -- ([EmployeeId], -- NOT NEEDED
    ([FirstName],
    [LastName],
    [MiddleName],
    [JobTitle],
    [DepartmentId],
    [Salary])
-- VALUES
--     (@employeeID,
--         @firstName,
--         @lastName,
--         @middleName,
--         @jobTitle,
--         @departmentId,
--         @salary)
SELECT
    -- [EmployeeId], NOT NEEDED !!!
    [FirstName],
    [LastName],
    [MiddleName],
    [JobTitle],
    [DepartmentId],
    [Salary]
FROM deleted
-- IMPORTANT instead of VALUES, directly SELECT can be used

GO
