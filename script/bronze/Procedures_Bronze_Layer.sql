/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from:
    - Structured CSV files (CRM & ERP)
    - Semi-structured JSON files (Web data)

    It performs:
    - Enables OPENROWSET if not already enabled
    - Truncates bronze tables
    - Ingestion of the CRM & ERP CSV files via BULK INSERT into bronze staging tables
    - Ingestion of JSON via OPENROWSET + OPENJSON into bronze staging tables

    
Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time DATETIME;

    BEGIN TRY

    /* =======================================================
       Enable OPENROWSET (Ad Hoc Distributed Queries)
    ======================================================== */
    IF NOT EXISTS (
        SELECT 1
        FROM sys.configurations
        WHERE name = 'Ad Hoc Distributed Queries'
          AND value_in_use = 1
    )
    BEGIN
        PRINT '>> Enabling Ad Hoc Distributed Queries (OPENROWSET)...';

        EXEC sp_configure 'show advanced options', 1;
        RECONFIGURE;

        EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
        RECONFIGURE;

        PRINT '>> OPENROWSET Enabled Successfully';
    END
    ELSE
    BEGIN
        PRINT '>> OPENROWSET Already Enabled';
    END;

    SET @batch_start_time = GETDATE();

    PRINT '================================================';
    PRINT 'Loading Bronze Layer';
    PRINT '================================================';

    /* =======================================================
       CRM TABLES
    ======================================================== */
    PRINT '------------------------------------------------';
    PRINT 'Loading CRM Tables';
    PRINT '------------------------------------------------';

    -- bronze.crm_cust_info
    SET @start_time = GETDATE();
    PRINT '>> Truncating Table: bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;

    PRINT '>> Inserting Data Into: bronze.crm_cust_info';
    BULK INSERT bronze.crm_cust_info
    FROM 'C:\SQLDATA\datasets\source_crm\cust_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0d0a',
        TABLOCK,
        CODEPAGE = '65001'
    );

    PRINT '>> Inserted Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));
    SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
    PRINT '>> -------------';


    -- bronze.crm_prd_info
    SET @start_time = GETDATE();
    PRINT '>> Truncating Table: bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;

    PRINT '>> Inserting Data Into: bronze.crm_prd_info';
    BULK INSERT bronze.crm_prd_info
    FROM 'C:\SQLDATA\datasets\source_crm\prd_info.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0d0a',
        TABLOCK,
        CODEPAGE = '65001'
    );

    PRINT '>> Inserted Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));
    SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
    PRINT '>> -------------';


    -- bronze.crm_sales_details
    SET @start_time = GETDATE();
    PRINT '>> Truncating Table: bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;

    PRINT '>> Inserting Data Into: bronze.crm_sales_details';
    BULK INSERT bronze.crm_sales_details
    FROM 'C:\SQLDATA\datasets\source_crm\sales_details.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0d0a',
        TABLOCK,
        CODEPAGE = '65001'
    );

    PRINT '>> Inserted Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));
    SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
    PRINT '>> -------------';


    /* =======================================================
       ERP TABLES
    ======================================================== */
    PRINT '------------------------------------------------';
    PRINT 'Loading ERP Tables';
    PRINT '------------------------------------------------';

    -- bronze.erp_loc_a101
    SET @start_time = GETDATE();
    PRINT '>> Truncating Table: bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;

    PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
    BULK INSERT bronze.erp_loc_a101
    FROM 'C:\SQLDATA\datasets\source_erp\loc_a101.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0d0a',
        TABLOCK,
        CODEPAGE = '65001'
    );

    PRINT '>> Inserted Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));
    SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
    PRINT '>> -------------';



    -- bronze.erp_px_cat_g1v2
    SET @start_time = GETDATE();
    PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
    BULK INSERT bronze.erp_px_cat_g1v2
    FROM 'C:\SQLDATA\datasets\source_erp\px_cat_g1v2.csv'
    WITH (
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0d0a',
        TABLOCK,
        CODEPAGE = '65001'
    );

    PRINT '>> Inserted Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));
    SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
    PRINT '>> -------------';


    /* =======================================================
       WEB JSON TABLES (DATA LAKE)
    ======================================================== */
    PRINT '------------------------------------------------';
    PRINT 'Loading Web JSON Tables';
    PRINT '------------------------------------------------';
    -- ------------------- web_sessions -------------------

    SET @start_time = GETDATE();
    PRINT '>> Truncating Table: bronze.web_sessions';
    TRUNCATE TABLE bronze.web_sessions;

    INSERT INTO bronze.web_sessions
    SELECT *
    FROM OPENJSON(
        (SELECT BulkColumn
         FROM OPENROWSET(
            BULK 'C:\SQLDATA\datasets\source_web\web_sessions.json',
            SINGLE_CLOB
         ) AS j)
    )
    WITH (
        session_id NVARCHAR(50),
        customer_id INT,
        session_start DATETIME,
        session_end DATETIME,
        device_type NVARCHAR(50),
        traffic_source NVARCHAR(50),
        country NVARCHAR(50)
    );

    PRINT '>> Inserted Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));
    SET @end_time = GETDATE();
    PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
    PRINT '>> -------------';


    SET @batch_end_time = GETDATE();

    PRINT '==========================================';
    PRINT 'Loading Bronze Layer is Completed';
    PRINT '   - Total Load Duration: '
          + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20))
          + ' seconds';
    PRINT '==========================================';


-- ------------------- web_events -------------------
SET @start_time = GETDATE();
PRINT '>> Truncating Table: bronze.web_events';
TRUNCATE TABLE bronze.web_events;

PRINT '>> Inserting Data Into: bronze.web_events';
INSERT INTO bronze.web_events (
    event_id,
    session_id,
    customer_id,
    event_type,
    product_key,
    event_timestamp
)
SELECT
    TRY_CAST(event_id AS INT) AS event_id,
    session_id,
    TRY_CAST(customer_id AS INT) AS customer_id,
    event_type,
    product_key,
    TRY_CAST(event_timestamp AS DATETIME) AS event_timestamp
FROM OPENJSON(
    (SELECT BulkColumn
     FROM OPENROWSET(
        BULK 'C:\SQLDATA\datasets\source_web\web_events.json',
        SINGLE_CLOB
     ) AS j)
)
WITH (
    event_id NVARCHAR(50),
    session_id NVARCHAR(50),
    customer_id NVARCHAR(50),
    event_type NVARCHAR(50),
    product_key NVARCHAR(50),
    event_timestamp NVARCHAR(50)
);

PRINT '>> Inserted Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));
SET @end_time = GETDATE();
PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
PRINT '>> -------------';


-- ------------------- web_conversions -------------------
SET @start_time = GETDATE();
PRINT '>> Truncating Table: bronze.web_conversions';
TRUNCATE TABLE bronze.web_conversions;

PRINT '>> Inserting Data Into: bronze.web_conversions';
INSERT INTO bronze.web_conversions (
    conversion_id,
    session_id,
    order_number,
    conversion_timestamp,
    revenue
)
SELECT
    TRY_CAST(conversion_id AS INT) AS conversion_id,
    session_id,
    order_number,
    TRY_CAST(conversion_timestamp AS DATETIME) AS conversion_timestamp,
    TRY_CAST(revenue AS DECIMAL(18,2)) AS revenue
FROM OPENJSON(
    (SELECT BulkColumn
     FROM OPENROWSET(
        BULK 'C:\SQLDATA\datasets\source_web\web_conversions.json',
        SINGLE_CLOB
     ) AS j)
)
WITH (
    conversion_id NVARCHAR(50),
    session_id NVARCHAR(50),
    order_number NVARCHAR(50),
    conversion_timestamp NVARCHAR(50),
    revenue NVARCHAR(50)
);

PRINT '>> Inserted Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));
SET @end_time = GETDATE();
PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
PRINT '>> -------------';

PRINT '================================================';
PRINT 'All Web JSON Tables Loaded Successfully';
PRINT '================================================';
 END TRY
    BEGIN CATCH
        PRINT 'ERROR OCCURED: ' + ERROR_MESSAGE();
    END CATCH
END


   -- EXEC bronze.load_bronze--