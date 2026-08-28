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
        Name NVARCHAR(200) NOT NULL,
        Price DECIMAL(10, 2) NOT NULL,
        Stock INT NOT NULL,
        Description NVARCHAR(500) NOT NULL,
        ImageUrl NVARCHAR(2048) NOT NULL,
        IsActive BIT NOT NULL
            CONSTRAINT DF_Product_IsActive DEFAULT (1),
        Version INT NOT NULL
            CONSTRAINT DF_Product_Version DEFAULT (0),
        CONSTRAINT CK_Product_Price CHECK (Price > 0),
        CONSTRAINT CK_Product_Stock CHECK (Stock >= 0),
        CONSTRAINT CK_Product_Description CHECK (LEN(LTRIM(RTRIM(Description))) > 0),
        CONSTRAINT CK_Product_ImageUrl CHECK
            (ImageUrl LIKE N'http://_%' OR ImageUrl LIKE N'https://_%')
    );
END;
GO

-- Upgrade existing installations without deleting their products.
IF COL_LENGTH(N'dbo.Product', N'Description') IS NULL
BEGIN
    ALTER TABLE dbo.Product
        ADD Description NVARCHAR(500) NOT NULL
            CONSTRAINT DF_Product_Description DEFAULT (N'Sin descripción') WITH VALUES;
END;
GO

IF COL_LENGTH(N'dbo.Product', N'ImageUrl') IS NULL
BEGIN
    ALTER TABLE dbo.Product
        ADD ImageUrl NVARCHAR(2048) NOT NULL
            CONSTRAINT DF_Product_ImageUrl
            DEFAULT (N'https://example.com/producto.png') WITH VALUES;
END;
GO

IF COL_LENGTH(N'dbo.Product', N'IsActive') IS NULL
BEGIN
    ALTER TABLE dbo.Product
        ADD IsActive BIT NOT NULL
            CONSTRAINT DF_Product_IsActive DEFAULT (1) WITH VALUES;
END;
GO

ALTER TABLE dbo.Product ALTER COLUMN Name NVARCHAR(200) NOT NULL;
ALTER TABLE dbo.Product ALTER COLUMN Description NVARCHAR(500) NOT NULL;
ALTER TABLE dbo.Product ALTER COLUMN ImageUrl NVARCHAR(2048) NOT NULL;
GO

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

    ALTER TABLE dbo.Product ALTER COLUMN Version INT NOT NULL;

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

-- Remove RowVersion if an earlier partial execution added it.
IF COL_LENGTH(N'dbo.Product', N'RowVersion') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Product DROP COLUMN RowVersion;
END;
GO

IF OBJECT_ID(N'dbo.CK_Product_Description', N'C') IS NULL
BEGIN
    ALTER TABLE dbo.Product WITH CHECK
        ADD CONSTRAINT CK_Product_Description
        CHECK (LEN(LTRIM(RTRIM(Description))) > 0);
END;
GO

IF OBJECT_ID(N'dbo.CK_Product_ImageUrl', N'C') IS NULL
BEGIN
    ALTER TABLE dbo.Product WITH CHECK
        ADD CONSTRAINT CK_Product_ImageUrl
        CHECK (ImageUrl LIKE N'http://_%' OR ImageUrl LIKE N'https://_%');
END;
GO

SELECT Id, Name, Price, Stock, Description, ImageUrl, IsActive, Version
FROM dbo.Product;
GO
