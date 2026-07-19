



CREATE SCHEMA audit
CREATE SCHEMA stg
CREATE SCHEMA dw

CREATE TABLE audit.FileControl
(
    TableName NVARCHAR(100),
    FileName NVARCHAR(300),
    LastModified DATETIME2,
    FileSize BIGINT NULL,

    IsProcessed BIT DEFAULT 0,
    Status NVARCHAR(50) DEFAULT 'REGISTERED',

    InsertedDate DATETIME DEFAULT GETDATE(),
    ProcessedDate DATETIME NULL,
    UpdatedDate DATETIME NULL,

    CONSTRAINT PK_FileControl 
        PRIMARY KEY (TableName, FileName)
);



SELECT * FROM audit.FileControl
--Create Metadata Configuration Table
--DROP TABLE audit.ETL_Config
CREATE TABLE audit.ETL_Config
(   
    FolderPath NVARCHAR(200),
    StagingTable NVARCHAR(200),
    TargetTable NVARCHAR(200),
    LoadProcedure NVARCHAR(200),

    LoadPattern NVARCHAR(50), 

    WatermarkColumn NVARCHAR(100) NULL,

    SCDColumns NVARCHAR(1000) NULL,
    SCDType INT NULL,

    IsActive BIT DEFAULT 1,

    BusinessKeyColumn VARCHAR(100),
    BusinessColumns VARCHAR(MAX),
    DateColumns VARCHAR(MAX)
);


INSERT INTO audit.ETL_Config(FolderPath,StagingTable,TargetTable,IsActive,BusinessKeyColumn,BusinessColumns,SCDColumns,DateColumns) 
VALUES('Products','stg.dimproduct','dw.dimproduct',1,'ProductID','SKUCode,ProductName,ShortDescription,Category,SubCategory,Department,Brand,ModelNumber,Color,Size,Weight,UnitOfMeasure,SupplierID,SupplierName,CountryOfOrigin,CostPrice,MRP,StandardSellingPrice,TaxPercent,ReorderLevel,ProductStatus','CostPrice,MRP,StandardSellingPrice,TaxPercent,ProductStatus','LaunchDate')


INSERT INTO audit.ETL_Config(FolderPath,StagingTable,TargetTable,IsActive,BusinessKeyColumn,BusinessColumns,SCDColumns,DateColumns) 
VALUES('Customers','stg.DimCustomer','dw.DimCustomer',1,'CustomerID','FirstName,LastName,Email,PhoneNumber,AddressLine1,AddressLine2,City,StateProvince,PostalCode,Country,CustomerSegment,CustomerCategory,LoyaltyPoints,CustomerStatus',
       'CustomerNumber,FirstName,LastName,FullName,Gender,Email,PhoneNumber,AddressLine1,AddressLine2,City,StateProvince,PostalCode,Country,CustomerSegment,CustomerCategory,RegistrationDate,PreferredLanguage,PreferredCurrency,LoyaltyProgramID,LoyaltyPoints,MarketingOptIn,EmailOptIn,SMSOptIn,CustomerStatus','DateOfBirth,RegistrationDate'
)

INSERT INTO audit.ETL_Config(FolderPath,StagingTable,TargetTable,IsActive,BusinessKeyColumn,BusinessColumns,SCDColumns,DateColumns) 
VALUES('Stores','stg.DimStore','dw.DimStore',1,'StoreID','StoreCode,StoreName,StoreType,StoreFormat,AddressLine1,AddressLine2,City,StateProvince,PostalCode,Country,Region,Latitude,Longitude,StoreManager,ManagerEmail,ManagerPhone,StoreSizeSqFt,NumberOfEmployees,IsFranchise,StoreStatus,TargetRevenue',
       'StoreName,StoreManager,ManagerEmail,ManagerPhone,StoreSizeSqFt,NumberOfEmployees,StoreStatus,TargetRevenue','OpeningDate,ClosingDate'
)

INSERT INTO audit.ETL_Config(FolderPath,StagingTable,TargetTable,IsActive,BusinessKeyColumn,BusinessColumns,SCDColumns,DateColumns) 
VALUES('Sales','stg.FactSales','dw.FactSales',1,'StoreID','StoreCode,StoreName,StoreType,StoreFormat,AddressLine1,AddressLine2,City,StateProvince,PostalCode,Country,Region,Latitude,Longitude,StoreManager,ManagerEmail,ManagerPhone,StoreSizeSqFt,NumberOfEmployees,IsFranchise,StoreStatus,TargetRevenue',
       'StoreName,StoreManager,ManagerEmail,ManagerPhone,StoreSizeSqFt,NumberOfEmployees,StoreStatus,TargetRevenue','OpeningDate,ClosingDate'
)


UPDATE audit.ETL_Config SET IsActive =1 WHERE TargetTable = 'dw.DimPromotion'


SELECT * FROM audit.ETL_Config



CREATE TABLE audit.FileWatermarkControl
(
    TableName NVARCHAR(100),
    LastProcessedFileTime DATETIME2,
    LastUpdated DATETIME DEFAULT GETDATE()
);


CREATE OR ALTER PROCEDURE audit.usp_RegisterFileMetadata
    @TableName NVARCHAR(100),
    @FileName NVARCHAR(300),
    @LastModified DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    MERGE audit.FileControl AS target
    USING (
        SELECT @TableName AS TableName,
               @FileName AS FileName
    ) AS source
    ON target.TableName = source.TableName
       AND target.FileName = source.FileName

    WHEN MATCHED AND target.LastModified <> @LastModified
        THEN UPDATE SET
            LastModified = @LastModified,
            IsProcessed = 0,
            Status = 'UPDATED',
            UpdatedDate = GETDATE()

    WHEN NOT MATCHED THEN
        INSERT (TableName, FileName, LastModified,  IsProcessed, Status, InsertedDate)
        VALUES (@TableName, @FileName, @LastModified,  0, 'REGISTERED', GETDATE());
END;

