-- =======================================================================
-- OULAD - PHASE 1: Import Data & Staging
-- =======================================================================

-- 1. Create New Database
CREATE DATABASE OULAD
USE OULAD
GO
--====================================================

-- 2. Create the Staging schema.
IF SCHEMA_ID(N'stg') IS NULL
    EXEC(N'CREATE SCHEMA [stg] AUTHORIZATION [dbo];');
GO
--====================================================

-- 3. Create raw tables in the ORIGINAL CSV column order.

CREATE TABLE [stg].[raw_courses]
(
   [code_module] NVARCHAR(255) NULL,
   [code_presentation] NVARCHAR(255) NULL,
   [module_presentation_length] NVARCHAR(255) NULL
);

CREATE TABLE [stg].[raw_assessments]
    (
        [code_module] NVARCHAR(255) NULL,
        [code_presentation] NVARCHAR(255) NULL,
        [id_assessment] NVARCHAR(255) NULL,
        [assessment_type] NVARCHAR(255) NULL,
        [date] NVARCHAR(255) NULL,
        [weight] NVARCHAR(255) NULL
    );

CREATE TABLE [stg].[raw_vle]
    (
        [id_site] NVARCHAR(255) NULL,
        [code_module] NVARCHAR(255) NULL,
        [code_presentation] NVARCHAR(255) NULL,
        [activity_type] NVARCHAR(255) NULL,
        [week_from] NVARCHAR(255) NULL,
        [week_to] NVARCHAR(255) NULL
    );

CREATE TABLE [stg].[raw_studentInfo]
    (
        [code_module] NVARCHAR(255) NULL,
        [code_presentation] NVARCHAR(255) NULL,
        [id_student] NVARCHAR(255) NULL,
        [gender] NVARCHAR(255) NULL,
        [region] NVARCHAR(255) NULL,
        [highest_education] NVARCHAR(255) NULL,
        [imd_band] NVARCHAR(255) NULL,
        [age_band] NVARCHAR(255) NULL,
        [num_of_prev_attempts] NVARCHAR(255) NULL,
        [studied_credits] NVARCHAR(255) NULL,
        [disability] NVARCHAR(255) NULL,
        [final_result] NVARCHAR(255) NULL
    );

CREATE TABLE [stg].[raw_studentRegistration]
    (
        [code_module] NVARCHAR(255) NULL,
        [code_presentation] NVARCHAR(255) NULL,
        [id_student] NVARCHAR(255) NULL,
        [date_registration] NVARCHAR(255) NULL,
        [date_unregistration] NVARCHAR(255) NULL
    );

CREATE TABLE [stg].[raw_studentAssessment]
    (
        [id_assessment] NVARCHAR(255) NULL,
        [id_student] NVARCHAR(255) NULL,
        [date_submitted] NVARCHAR(255) NULL,
        [is_banked] NVARCHAR(255) NULL,
        [score] NVARCHAR(255) NULL
    );

CREATE TABLE [stg].[raw_studentVle]
    (
        [code_module] NVARCHAR(255) NULL,
        [code_presentation] NVARCHAR(255) NULL,
        [id_student] NVARCHAR(255) NULL,
        [id_site] NVARCHAR(255) NULL,
        [date] NVARCHAR(255) NULL,
        [sum_click] NVARCHAR(255) NULL
    );

--====================================================
-- 4. Import all seven original CSV files.

SET NOCOUNT ON;       -- لعدم ظهور رسالة (.. row affected)
SET XACT_ABORT ON;    -- إلغاء المعاملة بالكامل لو حصل خطأ داخل ال transaction

IF @@TRANCOUNT <> 0   -- التأكد من عدم وجود transaction مفتوحة
    THROW 50000, 'Close the existing transaction before running the import.', 1;

INSERT INTO stg.raw_courses
SELECT * 
FROM dbo.courses; 
SELECT * FROM stg.raw_courses

INSERT INTO stg.raw_assessments
SELECT * 
FROM dbo.assessments; 
SELECT * FROM stg.raw_assessments

INSERT INTO stg.raw_vle
SELECT * 
FROM dbo.vle; 
SELECT * FROM stg.raw_vle

INSERT INTO stg.raw_studentInfo
SELECT * 
FROM dbo.studentInfo; 
SELECT * FROM stg.raw_studentInfo

INSERT INTO stg.raw_studentRegistration
SELECT * 
FROM dbo.studentRegistration; 
SELECT * FROM stg.raw_studentRegistration

INSERT INTO stg.raw_studentAssessment
SELECT * 
FROM dbo.studentAssessment; 
SELECT * FROM stg.raw_studentAssessment

INSERT INTO stg.raw_studentVle
SELECT * 
FROM dbo.studentVle; 
SELECT * FROM stg.raw_studentVle

--====================================================
-- 5. Drop original tables.

DROP TABLE dbo.courses
DROP TABLE dbo.assessments
DROP TABLE dbo.studentInfo
DROP TABLE dbo.vle
DROP TABLE dbo.studentRegistration
DROP TABLE dbo.studentAssessment
DROP TABLE dbo.studentVle
--====================================================

-- 5. Verify import counts. Select/run this separately after a failed import.

SELECT N'courses.csv' AS SourceFile, COUNT_BIG(*) AS ImportedRows
FROM [stg].[raw_courses]
UNION ALL
SELECT N'assessments.csv' AS SourceFile, COUNT_BIG(*) AS ImportedRows
FROM [stg].[raw_assessments]
UNION ALL
SELECT N'vle.csv' AS SourceFile, COUNT_BIG(*) AS ImportedRows
FROM [stg].[raw_vle]
UNION ALL
SELECT N'studentInfo.csv' AS SourceFile, COUNT_BIG(*) AS ImportedRows
FROM [stg].[raw_studentInfo]
UNION ALL
SELECT N'studentRegistration.csv' AS SourceFile, COUNT_BIG(*) AS ImportedRows
FROM [stg].[raw_studentRegistration]
UNION ALL
SELECT N'studentAssessment.csv' AS SourceFile, COUNT_BIG(*) AS ImportedRows
FROM [stg].[raw_studentAssessment]
UNION ALL
SELECT N'studentVle.csv' AS SourceFile, COUNT_BIG(*) AS ImportedRows
FROM [stg].[raw_studentVle];

-- 6. Preview a small sample; do not SELECT * from the full studentVle table.
SELECT TOP (5) * FROM [stg].[raw_courses];
SELECT TOP (5) * FROM [stg].[raw_assessments];
SELECT TOP (5) * FROM [stg].[raw_vle];
SELECT TOP (5) * FROM [stg].[raw_studentInfo];
SELECT TOP (5) * FROM [stg].[raw_studentRegistration];
SELECT TOP (5) * FROM [stg].[raw_studentAssessment];
SELECT TOP (5) * FROM [stg].[raw_studentVle];

