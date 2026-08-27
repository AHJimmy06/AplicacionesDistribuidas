IF DB_ID(N'AppDistribuidas_2026_DB') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE AppDistribuidas_2026_DB');
END;
GO

USE AppDistribuidas_2026_DB;
GO

IF OBJECT_ID(N'dbo.Product', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Product
    (
        Id INT IDENTITY(1, 1) NOT NULL
            CONSTRAINT PK_Product PRIMARY KEY,
        Name VARCHAR(200) NOT NULL,
        Price DECIMAL(10, 2) NOT NULL,
        Stock INT NOT NULL,
        Version INT NOT NULL
            CONSTRAINT DF_Product_Version DEFAULT (0),
        CONSTRAINT CK_Product_Price CHECK (Price > 0),
        CONSTRAINT CK_Product_Stock CHECK (Stock >= 0)
    );
END;
GO

-- Upgrade an existing Product table that does not have a usable Version column.
IF COL_LENGTH(N'dbo.Product', N'Version') IS NULL
BEGIN
    ALTER TABLE dbo.Product
        ADD Version INT NOT NULL
            CONSTRAINT DF_Product_Version DEFAULT (0) WITH VALUES;
END
ELSE
BEGIN
    UPDATE dbo.Product
    SET Version = 0
    WHERE Version IS NULL;

    ALTER TABLE dbo.Product
        ALTER COLUMN Version INT NOT NULL;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.default_constraints AS dc
        INNER JOIN sys.columns AS c
            ON c.default_object_id = dc.object_id
        WHERE dc.parent_object_id = OBJECT_ID(N'dbo.Product')
          AND c.name = N'Version'
    )
    BEGIN
        ALTER TABLE dbo.Product
            ADD CONSTRAINT DF_Product_Version DEFAULT (0) FOR Version;
    END;
END;
GO

SELECT Id, Name, Price, Stock, Version
FROM dbo.Product;
GO
