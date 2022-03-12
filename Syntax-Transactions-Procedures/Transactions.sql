USE [Bank]
SELECT *
FROM [Accounts]

-- 19.
GO
CREATE OR ALTER TRIGGER tg_UpdateLogsOnAccountsChange
ON [Accounts]
AFTER UPDATE
AS
SET NOCOUNT ON
INSERT INTO [Logs]
    ([AccountId], [OldAmount], [NewAmount])
(SELECT
    [i].[Id],
    [d].[Balance],
    [i].[Balance]
FROM inserted AS [i]
    JOIN deleted AS [d]
    ON [d].[Id] = [i].[Id]
WHERE [d].[Balance] != [i].[Balance])
-- JUDGE SUBMIT WITHOUT GO !!!
GO

EXEC usp_TransferFund 2, 1, 4000

SELECT *
FROM [Logs]

EXEC usp_TransferFund 1, 2, 4000

-- Alternative
GO
CREATE TRIGGER tr_AccountBalanceChange
ON Accounts FOR UPDATE
AS
BEGIN
    DECLARE @accountId int = (SELECT Id
    FROM inserted);
    DECLARE @oldBalance money = (SELECT Balance
    FROM deleted);
    DECLARE @newBalance money = (SELECT Balance
    FROM inserted);

    IF (@newBalance <> @oldBalance)
    BEGIN
        INSERT INTO Logs
        VALUES
            (@accountId, @oldBalance, @newBalance);
    END
END

ENABLE TRIGGER ALL
ON [Accounts]
GO
DISABLE TRIGGER tg_UpdateLogsOnAccountsChange
ON [Accounts]
GO
-- 20.
CREATE TABLE NotificationEmails
(
    [Id] INT IDENTITY(1, 1) PRIMARY KEY NOT NULL,
    [Recipient] INT FOREIGN KEY REFERENCES [Accounts]([Id]) NOT NULL,
    [Subject] NVARCHAR(200) NOT NULL,
    [Body] NVARCHAR(MAX) NOT NULL,
)

GO
CREATE OR ALTER TRIGGER tr_CreateEmailOnLogsUpdate
ON [Logs] AFTER INSERT
AS
SET NOCOUNT ON
DECLARE @accountId INT = (SELECT [AccountId]
FROM inserted);
DECLARE @date DATETIME2 = FORMAT(GETDATE(), 'MMM dd yyyy h:mmtt', 'en-US');
DECLARE @oldSum MONEY = (SELECT [OldAmount]
FROM inserted);
DECLARE @newSum MONEY = (SELECT [NewAmount]
FROM inserted);
DECLARE @subject NVARCHAR(200) = CONCAT('Balance change for account: ', @accountId);
-- DECLARE @body NVARCHAR(MAX) = CONCAT('On ', @date, ' your balance was changed from ', @oldSum, ' to ', @newSum,'.');
DECLARE @body NVARCHAR(MAX) = CONCAT('On ', FORMAT(GETDATE(), 'MMM dd yyyy h:mm', 'en-US'), ' your balance was changed from ', @oldSum, ' to ', @newSum,'.');

INSERT INTO [NotificationEmails]
    ([Recipient], [Subject], [Body])
VALUES
    (@accountId, @subject, @body)
GO

SELECT *
FROM [NotificationEmails]

-- tt => AM/PM
SELECT FORMAT(GETDATE(), 'MMM dd yyyy h:mmtt', 'en-US');
-- ALternative CONVERT with 100-style !!!
SELECT CONVERT(VARCHAR(30), GETDATE(), 100)
-- 21.
GO
CREATE OR ALTER PROCEDURE usp_DepositMoney
    (@AccountId INT,
    @MoneyAmount DECIMAL(18, 4))
AS
BEGIN
    DECLARE @validAccount BIT = 0;

    IF ((SELECT COUNT(*)
    FROM [Accounts]
    WHERE [Id] = @AccountId)
         > 0)
    BEGIN
        SET @validAccount = 1;
    END

    IF (@MoneyAmount >= 0 AND @validAccount = 1)
    BEGIN
        UPDATE [Accounts]
        SET [Balance] += @MoneyAmount
        WHERE [Id] = @AccountId
    END
END
GO

-- HOW TO SET BIT VARIABLES
GO
DECLARE @test BIT = CASE WHEN (1 > 2) THEN
1
ELSE
0
END
SELECT @test
GO

-- @@ROWCOUNT returns the number of rows affected by last query!!!

SELECT *
FROM [Accounts]
SELECT @@ROWCOUNT

-- @@ ROWCOUNT DEMO
-- DECLARE @rowcount INT;
-- BEGIN TRY
--     SELECT TOP 100 * FROM [AdventureWorks2017].[Person].[Person];
--     SET @rowcount = @@ROWCOUNT;
-- END TRY
-- BEGIN CATCH
--     SELECT TOP 50 * FROM [AdventureWorks2017].[Person].[Person];
--     SET @rowcount = @@ROWCOUNT;
-- END CATCH
-- SELECT @rowcount;

-- SET ROWCOUNT LIMIT
-- SET ROWCOUNT 500

-- 22.
GO
CREATE OR ALTER PROCEDURE usp_WithdrawMoney
    (@AccountId INT,
    @MoneyAmount DECIMAL(18, 4))
AS
BEGIN
    IF (EXISTS(SELECT [Id]
    FROM [Accounts]
    WHERE [Id] = @AccountId))
    BEGIN
        BEGIN TRANSACTION
        IF (@MoneyAmount <= 0)
        BEGIN
            ROLLBACK;
            THROW 50001, 'Money can not be negative!', 1;
        END

        UPDATE [Accounts]
        SET [Balance] -= @MoneyAmount
        WHERE [Id] = @AccountId
        COMMIT TRANSACTION
    END
END
GO

-- 23.
GO
CREATE OR ALTER PROCEDURE usp_TransferMoney
    (@SenderId INT,
    @ReceiverId INT,
    @Amount DECIMAL(18, 4))
AS
BEGIN TRANSACTION
IF (@Amount <= 0)
BEGIN
    ROLLBACK;
    THROW 50001, 'Money must be positive amount', 1;
END

IF ((SELECT COUNT(*)
FROM [Accounts]
WHERE [Id] = @SenderId) <> 1)
BEGIN
    ROLLBACK;
    THROW 50002, 'Sender Accountnumber is not valid', 1;
END

IF ((SELECT COUNT(*)
FROM [Accounts]
WHERE [Id] = @ReceiverId) <> 1)
BEGIN
    ROLLBACK;
    THROW 50003, 'Receiver Accountnumber is not valid', 1;
END

IF (@SenderId = @ReceiverId)
BEGIN
    ROLLBACK;
    THROW 50004, 'Sender and Receiver accounts can not be the same!', 1;
END

-- UPDATE [Accounts]
-- SET [Balance] -= @Amount
-- WHERE [Id] = @SenderId

-- UPDATE [Accounts]
-- SET [Balance] += @Amount
-- WHERE [Id] = @ReceiverId

EXEC usp_WithdrawMoney @SenderId, @Amount
EXEC usp_DepositMoney @ReceiverId, @Amount

COMMIT TRANSACTION
GO

-- 24.
USE [Diablo]

SELECT *
FROM [Games]
SELECT *
FROM [Items]

-- 25.
SELECT *
FROM [Items]
WHERE [Id] IN
(SELECT [ItemId]
FROM [UserGameItems]
WHERE [UserGameId] IN (SELECT [Id]
FROM [Users]
WHERE [FirstName] = 'Stamat'))
ORDER BY [Name] ASC

SELECT *
FROM [Items]
WHERE [MinLevel] IN (11, 12, 19, 20, 21)
ORDER BY [Name] ASC
-- WHERE [MinLevel] BETWEEN 11 AND 12
-- AND [MinLevel] BETWEEN 19 AND 21