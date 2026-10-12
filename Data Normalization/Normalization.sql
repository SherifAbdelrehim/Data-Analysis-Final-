-- =======================================================================
-- OULAD - PHASE 3: ODS CREATION & LOADING
-- =======================================================================
USE OULAD
GO
--------------------------------------------
--------------------------------------------
/* فحص لمعرفة هل الطالب له خصائص مختلفة بين التسجيلات
أى هل معلومات الطلاب فريدة من نوعها مع كل طالب أم أحيانا تتغير مع الطالب نفسه */
WITH StudentProfiles AS
(
    SELECT
        id_student,
        gender,
        region,
        age_band,
        imd_band,
        highest_education,
        disability,

        ROW_NUMBER() OVER
        (
            PARTITION BY
                id_student,
                gender,
                region,
                age_band,
                imd_band,
                highest_education,
                disability
            ORDER BY id_student
        ) AS ProfileRowNumber

    FROM stg.vw_clean_studentInfo
),
ProfileCounts AS
(
    SELECT
        *,
        COUNT(*) OVER
        (
            PARTITION BY id_student
        ) AS DifferentProfilesCount

    FROM StudentProfiles
    WHERE ProfileRowNumber = 1
)
SELECT
    id_student,
    gender,
    region,
    age_band,
    imd_band,
    highest_education,
    disability,
    DifferentProfilesCount
FROM ProfileCounts
WHERE DifferentProfilesCount > 1
ORDER BY id_student;
-----------------------------------------------------------
-- لحساب عدد الصفوف التي تتطابق في كل الأعمدة المحددة معًا
WITH CheckDuplicates AS
(
    SELECT
        id_student,
        gender,
        region,
        age_band,
        imd_band,
        highest_education,
        disability,

        COUNT(*) OVER
        (
            PARTITION BY
                id_student,
                gender,
                region,
                age_band,
                imd_band,
                highest_education,
                disability
        ) AS MatchingRowsCount

    FROM stg.vw_clean_studentInfo
)
SELECT *
FROM CheckDuplicates
WHERE MatchingRowsCount > 1
ORDER BY id_student;
-------------------------------------------------------
-- حساب عدد مرات تكرار كل طالب فى جدول الطلاب وإظهار المكرر أكثر من مرة
SELECT
    id_student,
    COUNT(*) AS RepetitionCount
FROM stg.vw_clean_studentInfo
GROUP BY id_student
HAVING COUNT(*) > 1
ORDER BY RepetitionCount DESC, id_student;
--------------------------------------------------------------
-- بدون العمر
WITH StudentProfiles AS
(
    SELECT
        id_student,
        gender,
        region,
        imd_band,
        highest_education,
        disability,

        ROW_NUMBER() OVER
        (
            PARTITION BY
                id_student,
                gender,
                region,
                imd_band,
                highest_education,
                disability
            ORDER BY id_student
        ) AS ProfileRowNumber

    FROM stg.vw_clean_studentInfo
),
ProfileCounts AS
(
    SELECT
        *,
        COUNT(*) OVER
        (
            PARTITION BY id_student
        ) AS DifferentProfilesCount

    FROM StudentProfiles
    WHERE ProfileRowNumber = 1
)
SELECT
    id_student,
    gender,
    region,
    imd_band,
    highest_education,
    disability,
    DifferentProfilesCount
FROM ProfileCounts
WHERE DifferentProfilesCount > 1
ORDER BY id_student;
-------------------------------------------------------
-------------------------------------------------------
-- 1. هل يوجد أكثر من صف لنفس تقديم المقرر؟
SELECT
    code_module,
    code_presentation,
    COUNT_BIG(*) AS RowsPerKey
FROM stg.vw_clean_courses
GROUP BY code_module, code_presentation
HAVING COUNT_BIG(*) > 1;


-- 2. هل يوجد أكثر من صف لنفس تسجيل الطالب؟
SELECT
    id_student,
    code_module,
    code_presentation,
    COUNT_BIG(*) AS RowsPerKey
FROM stg.vw_clean_studentInfo
GROUP BY id_student, code_module, code_presentation
HAVING COUNT_BIG(*) > 1;


-- 3. هل يوجد أكثر من صف لبيانات التسجيل والانسحاب؟
SELECT
    id_student,
    code_module,
    code_presentation,
    COUNT_BIG(*) AS RowsPerKey
FROM stg.vw_clean_studentRegistration
GROUP BY id_student, code_module, code_presentation
HAVING COUNT_BIG(*) > 1;


-- 4. هل AssessmentID فريد؟
SELECT
    id_assessment,
    COUNT_BIG(*) AS RowsPerKey
FROM stg.vw_clean_assessments
GROUP BY id_assessment
HAVING COUNT_BIG(*) > 1;


-- 5. هل توجد أكثر من نتيجة لنفس الطالب والتقييم؟
SELECT
    id_student,
    id_assessment,
    COUNT_BIG(*) AS RowsPerKey
FROM stg.vw_clean_studentAssessment
GROUP BY id_student, id_assessment
HAVING COUNT_BIG(*) > 1;


-- 6. هل المورد فريد داخل تقديم المقرر؟
SELECT
    code_module,
    code_presentation,
    id_site,
    COUNT_BIG(*) AS RowsPerKey
FROM stg.vw_clean_vle
GROUP BY code_module, code_presentation, id_site
HAVING COUNT_BIG(*) > 1;


-- 7. تأكيد تفرد id_site على مستوى الموارد كلها
SELECT
    id_site,
    COUNT_BIG(*) AS RowsPerSite
FROM stg.vw_clean_vle
GROUP BY id_site
HAVING COUNT_BIG(*) > 1;
--------------------------------------------------------------------------

-- تأكيد أطوال رموز المقرر والتقديم لدمجمهما كمفتاح لجدول الكورسات
SELECT
    code_module,
    code_presentation,
    LEN(code_module) AS ModuleCodeLength,
    LEN(code_presentation) AS PresentationCodeLength
FROM stg.vw_clean_courses
WHERE code_module IS NULL
   OR code_presentation IS NULL
   OR LEN(code_module) <> 3
   OR LEN(code_presentation) <> 5;
----------------------------------------------------------------------------
-- مطابقة التسجيلات بين المصدرين في الاتجاهين
-- تسجيلات موجودة في studentInfo وغير موجودة في studentRegistration
SELECT
    id_student,
    code_module,
    code_presentation
FROM stg.vw_clean_studentInfo

EXCEPT

SELECT
    id_student,
    code_module,
    code_presentation
FROM stg.vw_clean_studentRegistration;


-- تسجيلات موجودة في studentRegistration وغير موجودة في studentInfo
SELECT
    id_student,
    code_module,
    code_presentation
FROM stg.vw_clean_studentRegistration

EXCEPT

SELECT
    id_student,
    code_module,
    code_presentation
FROM stg.vw_clean_studentInfo;
--------------------------------------------------------------------------------------------------------



-- =======================================================================
-- OULAD - PHASE 3: ODS CREATION & LOADING
-- =======================================================================

-- 0. Optional reset: ONLY select and execute these lines deliberately
-- if you intend to delete and rebuild these ODS tables and all their data.
-- DROP TABLE IF EXISTS ods.StudentDailyInteraction;
-- DROP TABLE IF EXISTS ods.StudentAssessment;
-- DROP TABLE IF EXISTS ods.Enrollment;
-- DROP TABLE IF EXISTS ods.LearningResource;
-- DROP TABLE IF EXISTS ods.Assessment;
-- DROP TABLE IF EXISTS ods.Student;
-- DROP TABLE IF EXISTS ods.CourseOffering;

-- 1. Create the schema if it does not exist.
IF SCHEMA_ID(N'ods') IS NULL
    EXEC(N'CREATE SCHEMA ods AUTHORIZATION dbo;');
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @@TRANCOUNT <> 0
    THROW 50001, 'Close the existing transaction before running this script.', 1;

IF OBJECT_ID(N'ods.Student') IS NOT NULL
   OR OBJECT_ID(N'ods.CourseOffering') IS NOT NULL
   OR OBJECT_ID(N'ods.Enrollment') IS NOT NULL
   OR OBJECT_ID(N'ods.Assessment') IS NOT NULL
   OR OBJECT_ID(N'ods.StudentAssessment') IS NOT NULL
   OR OBJECT_ID(N'ods.LearningResource') IS NOT NULL
   OR OBJECT_ID(N'ods.StudentDailyInteraction') IS NOT NULL
    THROW 50002, 'An ODS target already exists. Initial build stopped; existing tables were not changed.', 1;

-- =======================================================================
-- PART A: CREATE TABLES (DDL)
-- =======================================================================
BEGIN TRY
    BEGIN TRANSACTION;
    --1-- Student Table
    CREATE TABLE ods.Student
    (
        StudentID INT NOT NULL ,
        Gender NVARCHAR(1) NULL ,
        Region NVARCHAR(50) NULL ,
        HighestEducation NVARCHAR(50) NULL,
        IMDBand NVARCHAR(50) NULL ,
        Disability NVARCHAR(1) NULL ,
        CONSTRAINT PK_Student Primary Key (StudentID),
        CONSTRAINT CK_Student_Gender CHECK (Gender IN ('M','F')),
        CONSTRAINT CK_Student_Disability CHECK (Disability IN ('Y','N'))
    );
     
    --2-- CourseOffering Table
    CREATE TABLE ods.CourseOffering
    (
        CourseOfferingCode NVARCHAR(8) NOT NULL,
        ModuleCode NVARCHAR(3) NOT NULL,
        PresentationCode NVARCHAR(5) NOT NULL,
        PresentationLengthDays INT NOT NULL ,
        CONSTRAINT PK_CourseOffering Primary Key (CourseOfferingCode),
        CONSTRAINT CK_CourseOffering_Codes CHECK(CourseOfferingCode = LEFT(ModuleCode, 1) + PresentationCode),
        CONSTRAINT UQ_CourseOffering UNIQUE (ModuleCode, PresentationCode),
        CONSTRAINT CK_CourseOffering_PresentationLengthDays CHECK (PresentationLengthDays > 0)   
    );

    --3-- Enrollment Table
    CREATE TABLE ods.Enrollment
    (
        EnrollmentID INT IDENTITY(1,1) ,
        StudentID INT NOT NULL ,
        CourseOfferingCode NVARCHAR(8) NOT NULL ,
        AgeBand NVARCHAR(255) NULL,
        PreviousAttempts INT NULL ,
        StudiedCredits INT NULL ,
        FinalResult NVARCHAR(20) NULL ,
        RegistrationDay INT NULL,
        UnregistrationDay INT NULL,
        CONSTRAINT PK_Enrollment Primary Key (EnrollmentID),
        CONSTRAINT FK_Enrollment_Student FOREIGN KEY (StudentID) 
            REFERENCES ods.Student (StudentID),
        CONSTRAINT FK_Enrollment_CourseOfferingCode FOREIGN KEY (CourseOfferingCode) 
            REFERENCES ods.CourseOffering (CourseOfferingCode),
        CONSTRAINT UQ_Enrollment UNIQUE (StudentID, CourseOfferingCode),
        CONSTRAINT CK_Enrollment_PreviousAttempts CHECK (PreviousAttempts >= 0),
        CONSTRAINT CK_Enrollment_StudiedCredits CHECK (StudiedCredits >= 0),
        CONSTRAINT CK_Enrollment_FinalResult CHECK (FinalResult IN ('PASS', 'FAIL', 'WITHDRAWN', 'DISTINCTION'))
    );

    --4-- Assessment Table
    CREATE TABLE ods.Assessment
    (
        AssessmentID INT NOT NULL ,
        CourseOfferingCode NVARCHAR(8) NOT NULL ,
        AssessmentType NVARCHAR(10) NULL ,
        AssessmentDay INT NULL ,
        Weight DECIMAL(6,2) NULL ,
        CONSTRAINT PK_Assessment Primary Key (AssessmentID),
        CONSTRAINT FK_Assessment_CourseOfferingCode FOREIGN KEY (CourseOfferingCode) 
            REFERENCES ods.CourseOffering (CourseOfferingCode),
        CONSTRAINT CK_AssessmentType CHECK (AssessmentType IN (N'TMA', N'CMA', N'EXAM')), 
        CONSTRAINT CK_Weight CHECK (Weight BETWEEN 0 AND 100)
    );

    --5-- StudentAssessment Table
    CREATE TABLE ods.StudentAssessment
    (
        StudentAssessmentID INT IDENTITY(1,1) ,
        StudentID INT NOT NULL ,
        AssessmentID INT NOT NULL ,
        SubmittedDay INT NULL,
        IsBanked BIT NULL,
        Score DECIMAL(6,2) NULL ,
        CONSTRAINT PK_StudentAssessment Primary Key (StudentAssessmentID),
        CONSTRAINT FK_StudentAssessment_Student FOREIGN KEY (StudentID) 
            REFERENCES ods.Student (StudentID),
        CONSTRAINT FK_StudentAssessment_Assessment FOREIGN KEY (AssessmentID) 
            REFERENCES ods.Assessment (AssessmentID),
        CONSTRAINT UQ_StudentAssessment UNIQUE (StudentID, AssessmentID),
        CONSTRAINT CK_StudentAssessment_Score CHECK (Score BETWEEN 0 AND 100)
    );

    --6-- LearningResource Table
        CREATE TABLE ods.LearningResource
    (
        SiteID INT NOT NULL ,
        CourseOfferingCode NVARCHAR(8) NOT NULL ,
        ActivityType NVARCHAR(255) NULL,
        WeekFrom INT NULL,
        WeekTo INT NULL,
        CONSTRAINT PK_LearningResource Primary Key (SiteID),
        CONSTRAINT FK_LearningResource_CourseOfferingCode FOREIGN KEY (CourseOfferingCode) 
            REFERENCES ods.CourseOffering (CourseOfferingCode)
    );

    --7-- StudentDailyInteraction Table
    CREATE TABLE ods.StudentDailyInteraction
    (
        InteractionID BIGINT IDENTITY(1,1) ,
        StudentID INT NOT NULL ,
        SiteID INT NOT NULL ,
        InteractionDay INT NOT NULL,
        SumClicks BIGINT NOT NULL ,
        CONSTRAINT PK_StudentDailyInteraction Primary Key (InteractionID),
        CONSTRAINT FK_StudentDailyInteraction_Student FOREIGN KEY (StudentID) 
            REFERENCES ods.Student (StudentID),
        CONSTRAINT FK_StudentDailyInteraction_LearningResource FOREIGN KEY (SiteID) 
            REFERENCES ods.LearningResource (SiteID),
        CONSTRAINT UQ_StudentDailyInteraction UNIQUE (StudentID, SiteID, InteractionDay),
        CONSTRAINT CK_StudentDailyInteraction_SumClicks CHECK (SumClicks >= 0) 
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- =======================================================================
-- PART B: LOAD TABLES (INSERT ... SELECT)
-- Each table loads in its own transaction. A failed load stops this batch.
-- =======================================================================

-- 1. Student: one distinct set of stable attributes per StudentID.
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM ods.Student)
        THROW 50003, 'Student is not empty.', 1;

    INSERT INTO ods.Student
        (StudentID, Gender, Region, HighestEducation, IMDBand, Disability)
    SELECT DISTINCT
        id_student, gender, region, highest_education, imd_band, disability
    FROM stg.vw_clean_studentInfo;

    PRINT CONCAT('Student loaded: ', @@ROWCOUNT);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- 2. CourseOffering: code_module + code_presentation, e.g. AAA2013J.
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM ods.CourseOffering)
        THROW 50004, 'CourseOffering is not empty.', 1;

    INSERT INTO ods.CourseOffering
        (CourseOfferingCode, ModuleCode, PresentationCode, PresentationLengthDays)
    SELECT
        left(code_module,1) + code_presentation,
        code_module, code_presentation, module_presentation_length
    FROM stg.vw_clean_courses;

    PRINT CONCAT('CourseOffering loaded: ', @@ROWCOUNT);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- 3. Enrollment: match studentInfo with studentRegistration in BOTH directions.
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM ods.Enrollment)
        THROW 50005, 'Enrollment is not empty.', 1;

    IF EXISTS
    (
        SELECT id_student, code_module, code_presentation
        FROM stg.vw_clean_studentInfo
        EXCEPT
        SELECT id_student, code_module, code_presentation
        FROM stg.vw_clean_studentRegistration
    ) OR EXISTS
    (
        SELECT id_student, code_module, code_presentation
        FROM stg.vw_clean_studentRegistration
        EXCEPT
        SELECT id_student, code_module, code_presentation
        FROM stg.vw_clean_studentInfo
    )
        THROW 50006, 'Enrollment source keys do not match in both directions.', 1;

    INSERT INTO ods.Enrollment
    (
        StudentID, CourseOfferingCode, AgeBand, PreviousAttempts,
        StudiedCredits, FinalResult, RegistrationDay, UnregistrationDay
    )
    SELECT
        si.id_student,
        co.CourseOfferingCode,
        si.age_band,
        si.num_of_prev_attempts,
        si.studied_credits,
        si.final_result,
        sr.date_registration,
        sr.date_unregistration
    FROM stg.vw_clean_studentInfo AS si
    INNER JOIN stg.vw_clean_studentRegistration AS sr
        ON sr.id_student = si.id_student
       AND sr.code_module = si.code_module
       AND sr.code_presentation = si.code_presentation
    LEFT JOIN ods.CourseOffering AS co
        ON co.ModuleCode = si.code_module
       AND co.PresentationCode = si.code_presentation;

    PRINT CONCAT('Enrollment loaded: ', @@ROWCOUNT);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- 4. Assessment: one row per original AssessmentID.
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM ods.Assessment)
        THROW 50007, 'Assessment is not empty.', 1;

    INSERT INTO ods.Assessment
        (AssessmentID, CourseOfferingCode, AssessmentType, AssessmentDay, Weight)
    SELECT
        a.id_assessment, co.CourseOfferingCode,
        a.assessment_type, a.date, a.weight
    FROM stg.vw_clean_assessments AS a
    LEFT JOIN ods.CourseOffering AS co
        ON co.ModuleCode = a.code_module
       AND co.PresentationCode = a.code_presentation;

    PRINT CONCAT('Assessment loaded: ', @@ROWCOUNT);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- 5. StudentAssessment: the student must be enrolled in the assessment offering.
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM ods.StudentAssessment)
        THROW 50008, 'StudentAssessment is not empty.', 1;

    INSERT INTO ods.StudentAssessment
        (StudentID, AssessmentID, SubmittedDay, IsBanked, Score)
    SELECT
        e.StudentID, a.AssessmentID,
        sa.date_submitted, sa.is_banked, sa.score
    FROM stg.vw_clean_studentAssessment AS sa
    LEFT JOIN ods.Assessment AS a
        ON a.AssessmentID = sa.id_assessment
    LEFT JOIN ods.Enrollment AS e
        ON e.StudentID = sa.id_student
       AND e.CourseOfferingCode = a.CourseOfferingCode;

    PRINT CONCAT('StudentAssessment loaded: ', @@ROWCOUNT);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- 6. LearningResource: original SiteID is the PK; no extra ResourceKey.
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM ods.LearningResource)
        THROW 50009, 'LearningResource is not empty.', 1;

    INSERT INTO ods.LearningResource
        (SiteID, CourseOfferingCode, ActivityType, WeekFrom, WeekTo)
    SELECT
        v.id_site, co.CourseOfferingCode,
        v.activity_type, v.week_from, v.week_to
    FROM stg.vw_clean_vle AS v
    LEFT JOIN ods.CourseOffering AS co
        ON co.ModuleCode = v.code_module
       AND co.PresentationCode = v.code_presentation;

    PRINT CONCAT('LearningResource loaded: ', @@ROWCOUNT);
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- 7. StudentDailyInteraction: load the FULL clean studentVle view.
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM ods.StudentDailyInteraction)
        THROW 50010, 'StudentDailyInteraction is not empty.', 1;

        WITH DailyInteraction AS
        (
           SELECT 
                code_module, code_presentation, id_student, id_site, date,SUM(sum_click) AS sum_click
            FROM stg.vw_clean_studentVle
            GROUP BY
                code_module, code_presentation, id_student, id_site, date
        )
        INSERT INTO ods.StudentDailyInteraction
        ( StudentID, SiteID, InteractionDay, SumClicks )
        SELECT
            e.StudentID,
            r.SiteID,
            sv.date,
            sv.sum_click
        FROM DailyInteraction AS sv
        LEFT JOIN ods.CourseOffering AS co
            ON co.ModuleCode = sv.code_module
            AND co.PresentationCode = sv.code_presentation
        LEFT JOIN ods.LearningResource AS r
            ON r.SiteID = sv.id_site
            AND r.CourseOfferingCode = co.CourseOfferingCode
        LEFT JOIN ods.Enrollment AS e
            ON e.StudentID = sv.id_student
            AND e.CourseOfferingCode = co.CourseOfferingCode;

    PRINT CONCAT('StudentDailyInteraction loaded: ', ROWCOUNT_BIG());
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- =======================================================================
-- PART C: COUNTS & SMALL PREVIEWS
-- These are actual ODS counts, not published reference counts.
-- =======================================================================
SELECT N'Student' AS TableName, COUNT_BIG(*) AS LoadedRows FROM ods.Student
UNION ALL SELECT N'CourseOffering', COUNT_BIG(*) FROM ods.CourseOffering
UNION ALL SELECT N'Enrollment', COUNT_BIG(*) FROM ods.Enrollment
UNION ALL SELECT N'Assessment', COUNT_BIG(*) FROM ods.Assessment
UNION ALL SELECT N'StudentAssessment', COUNT_BIG(*) FROM ods.StudentAssessment
UNION ALL SELECT N'LearningResource', COUNT_BIG(*) FROM ods.LearningResource
UNION ALL SELECT N'StudentDailyInteraction', COUNT_BIG(*) FROM ods.StudentDailyInteraction;

SELECT TOP (10) * FROM ods.Student ORDER BY StudentID;
SELECT TOP (10) * FROM ods.CourseOffering ORDER BY CourseOfferingCode;
SELECT TOP (10) * FROM ods.Enrollment ORDER BY EnrollmentID;
SELECT TOP (10) * FROM ods.Assessment ORDER BY AssessmentID;
SELECT TOP (10) * FROM ods.StudentAssessment ORDER BY StudentAssessmentID;
SELECT TOP (10) * FROM ods.LearningResource ORDER BY SiteID;
SELECT TOP (10) * FROM ods.StudentDailyInteraction ORDER BY InteractionID;
-------------------------------------------------------------------------------------------------------







---------------------------------------------------------------
---------------------------------------------------------------
/* المشكلة دى حصلت عند الإدخال فى جدول التفاعلات حيث أن الصفوف متطابقة تماما عدا عدد النقرات 
والحل هو عمل CTE تجمع النقرات لو الصفوف متطابقة */
-- ده الإختبار 
SELECT *
FROM stg.vw_clean_studentVle
WHERE id_student = 6516
  AND id_site = 877011
  AND date = 204;

SELECT *
FROM stg.raw_studentVle
WHERE TRY_CAST(id_student AS INT) = 6516
  AND TRY_CAST(id_site AS INT) = 877011
  AND TRY_CAST(date AS INT) = 204;

-- التأكد من أن التجميع لم يؤثر على الإجمالى 
SELECT
    'Clean View' AS SourceName,
    SUM(sum_click) AS TotalClicks
FROM stg.vw_clean_studentVle

UNION ALL

SELECT
    'ODS',
    SUM(SumClicks)
FROM ods.StudentDailyInteraction;