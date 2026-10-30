--=====================================================
-- OULAD - PHASE 4: DENORMALIZATION & STAR SCHEMA
--=====================================================
/*
    (3) Fact Tables :
    Grain:
      FactEnrollment        : one student / course offering.
      FactStudentAssessment : one student / assessment (including banked records).
      FactDailyInteraction  : one student / resource / relative day.

    (6) Dimension Tables :
    Student, CourseOffering, FinalResult. Assessment, LearningResource, RelativeDay.
*/
-------------------------------------------------------------------------------------------------
USE OULAD;
GO
/*
OPTIONAL RESET: execute deliberately ONLY to delete an existing DW.
DROP TABLE IF EXISTS dw.FactDailyInteraction;
DROP TABLE IF EXISTS dw.FactStudentAssessment;
DROP TABLE IF EXISTS dw.FactEnrollment;
DROP TABLE IF EXISTS dw.DimRelativeDay;
DROP TABLE IF EXISTS dw.DimLearningResource;
DROP TABLE IF EXISTS dw.DimAssessment;
DROP TABLE IF EXISTS dw.DimFinalResult;
DROP TABLE IF EXISTS dw.DimCourseOffering;
DROP TABLE IF EXISTS dw.DimStudent;
*/
SET NOCOUNT ON;           -- لمنع ظهور رسائل عدد الصفوف بعد كل أمر لتقلّيل الرسائل أثناء تحميل الجداول
SET XACT_ABORT ON;        --    إلغاء الـ Transaction بالكامل بدل احتمال استمرار جزء من العملية 

IF @@TRANCOUNT <> 0                    -- يرجع عدد مستويات الـ Transactions المفتوحة في الجلسة الحالية
    THROW 51000, 'Close the existing transaction before running this script.', 1;

-- Create Schema
IF SCHEMA_ID(N'dw') IS NULL                      
    EXEC(N'CREATE SCHEMA dw AUTHORIZATION dbo;');

BEGIN TRY
    BEGIN TRANSACTION;

-- =====================================================================
-- 1. CREATE DIMENSION TABLES
-- =====================================================================
CREATE TABLE dw.DimStudent
(
    StudentID INT NOT NULL,
    Gender NVARCHAR(1) NULL,
    Region NVARCHAR(50) NULL,
    HighestEducation NVARCHAR(50) NULL,
    IMDBand NVARCHAR(50) NULL,
    Disability NVARCHAR(1) NULL,
    CONSTRAINT PK_DW_DimStudent PRIMARY KEY (StudentID)
);

CREATE TABLE dw.DimCourseOffering
(
    CourseOfferingCode NVARCHAR(8) NOT NULL,
    ModuleCode NVARCHAR(3) NOT NULL,
    PresentationCode NVARCHAR(5) NOT NULL,
    PresentationLengthDays INT NOT NULL,
    PresentationYear INT NULL,
    PresentationTerm NVARCHAR(1) NOT NULL,
    CONSTRAINT PK_DW_DimCourseOffering PRIMARY KEY (CourseOfferingCode),
    CONSTRAINT UQ_DW_DimCourseOffering UNIQUE (ModuleCode, PresentationCode),
    CONSTRAINT CK_DW_CourseOffering_Code
        CHECK (CourseOfferingCode = LEFT(ModuleCode, 1) + PresentationCode),
    CONSTRAINT CK_DW_CourseOffering_Length CHECK (PresentationLengthDays > 0)
);

CREATE TABLE dw.DimFinalResult
(
    FinalResultKey INT NOT NULL,
    FinalResult NVARCHAR(20) NOT NULL,
    IsSuccess BIT NOT NULL,
    IsWithdrawn BIT NOT NULL,
    CONSTRAINT PK_DW_DimFinalResult PRIMARY KEY (FinalResultKey),
    CONSTRAINT UQ_DW_DimFinalResult UNIQUE (FinalResult)
);

CREATE TABLE dw.DimAssessment
(
    AssessmentID INT NOT NULL,
    AssessmentType NVARCHAR(10) NULL,
    AssessmentDay INT NULL,
    Weight DECIMAL(6,2) NULL,
    CONSTRAINT PK_DW_DimAssessment PRIMARY KEY (AssessmentID),
    CONSTRAINT CK_DW_DimAssessment_Weight CHECK (Weight BETWEEN 0 AND 100)
);

CREATE TABLE dw.DimLearningResource
(
    SiteID INT NOT NULL,
    ActivityType NVARCHAR(255) NULL,
    WeekFrom INT NULL,
    WeekTo INT NULL,
    CONSTRAINT PK_DW_DimLearningResource PRIMARY KEY (SiteID)
);

CREATE TABLE dw.DimRelativeDay
(
    RelativeDay INT NOT NULL,
    StudyWeekNumber INT NULL, -- day 0-6 = week 1; negative days have no study week.
    DayPhase NVARCHAR(20) NOT NULL,
    IsBeforeStart BIT NOT NULL,
    CONSTRAINT PK_DW_DimRelativeDay PRIMARY KEY (RelativeDay)
);

-- =====================================================================
-- 2. CREATE FACT TABLES
-- =====================================================================

CREATE TABLE dw.FactEnrollment
(
    EnrollmentID INT NOT NULL,
    StudentID INT NOT NULL,
    CourseOfferingCode NVARCHAR(8) NOT NULL,
    AgeBand NVARCHAR(255) NULL,
    FinalResultKey INT NOT NULL,
    PreviousAttempts INT NULL,
    StudiedCredits INT NULL,
    RegistrationDay INT NULL,
    UnregistrationDay INT NULL,
    EnrollmentCount INT NOT NULL CONSTRAINT DF_DW_EnrollmentCount DEFAULT (1),
    CONSTRAINT PK_DW_FactEnrollment PRIMARY KEY (EnrollmentID),
    CONSTRAINT UQ_DW_FactEnrollment_Grain UNIQUE (StudentID, CourseOfferingCode),
    CONSTRAINT FK_DW_FactEnrollment_StudentID
        FOREIGN KEY (StudentID) REFERENCES dw.DimStudent (StudentID),
    CONSTRAINT FK_DW_FactEnrollment_CourseOfferingCode
        FOREIGN KEY (CourseOfferingCode) REFERENCES dw.DimCourseOffering (CourseOfferingCode),
    CONSTRAINT FK_DW_FactEnrollment_FinalResultKey
        FOREIGN KEY (FinalResultKey) REFERENCES dw.DimFinalResult (FinalResultKey),
    CONSTRAINT CK_DW_FactEnrollment_Count CHECK (EnrollmentCount = 1),
    CONSTRAINT CK_DW_FactEnrollment_Attempts CHECK (PreviousAttempts >= 0),
    CONSTRAINT CK_DW_FactEnrollment_Credits CHECK (StudiedCredits >= 0)
);

CREATE TABLE dw.FactStudentAssessment
(
    StudentAssessmentID INT NOT NULL,
    StudentID INT NOT NULL,
    CourseOfferingCode NVARCHAR(8) NOT NULL,
    FinalResultKey INT NOT NULL,
    AssessmentID INT NOT NULL,
    SubmittedDay INT NULL,
    IsBanked BIT NULL,
    Score DECIMAL(6,2) NULL,
    AssessmentRecordCount INT NOT NULL CONSTRAINT DF_DW_AssessmentRecordCount DEFAULT (1),
    CONSTRAINT PK_DW_FactStudentAssessment PRIMARY KEY (StudentAssessmentID),
    CONSTRAINT UQ_DW_FactStudentAssessment_Grain UNIQUE (StudentID, AssessmentID),
    CONSTRAINT FK_DW_FactStudentAssessment_StudentID
        FOREIGN KEY (StudentID) REFERENCES dw.DimStudent (StudentID),
    CONSTRAINT FK_DW_FactStudentAssessment_CourseOfferingCode
        FOREIGN KEY (CourseOfferingCode) REFERENCES dw.DimCourseOffering (CourseOfferingCode),
    CONSTRAINT FK_DW_FactStudentAssessment_FinalResultKey
        FOREIGN KEY (FinalResultKey) REFERENCES dw.DimFinalResult (FinalResultKey),
    CONSTRAINT FK_DW_FactStudentAssessment_AssessmentID
        FOREIGN KEY (AssessmentID) REFERENCES dw.DimAssessment (AssessmentID),
    CONSTRAINT CK_DW_FactStudentAssessment_Count CHECK (AssessmentRecordCount = 1),
    CONSTRAINT CK_DW_FactStudentAssessment_Score CHECK (Score BETWEEN 0 AND 100)
);

CREATE TABLE dw.FactDailyInteraction
(
    InteractionID BIGINT NOT NULL,
    StudentID INT NOT NULL,
    CourseOfferingCode NVARCHAR(8) NOT NULL,
    FinalResultKey INT NOT NULL,
    SiteID INT NOT NULL,
    InteractionDay INT NOT NULL,
    SumClicks BIGINT NOT NULL,
    CONSTRAINT PK_DW_FactDailyInteraction PRIMARY KEY (InteractionID),
    CONSTRAINT UQ_DW_FactDailyInteraction_Grain UNIQUE (StudentID, SiteID, InteractionDay),
    CONSTRAINT FK_DW_FactDailyInteraction_StudentID
        FOREIGN KEY (StudentID) REFERENCES dw.DimStudent (StudentID),
    CONSTRAINT FK_DW_FactDailyInteraction_CourseOfferingCode
        FOREIGN KEY (CourseOfferingCode) REFERENCES dw.DimCourseOffering (CourseOfferingCode),
    CONSTRAINT FK_DW_FactDailyInteraction_FinalResultKey
        FOREIGN KEY (FinalResultKey) REFERENCES dw.DimFinalResult (FinalResultKey),
    CONSTRAINT FK_DW_FactDailyInteraction_SiteID
        FOREIGN KEY (SiteID) REFERENCES dw.DimLearningResource (SiteID),
    CONSTRAINT FK_DW_FactDailyInteraction_InteractionDay
        FOREIGN KEY (InteractionDay) REFERENCES dw.DimRelativeDay (RelativeDay),
    CONSTRAINT CK_DW_FactDailyInteraction_Clicks CHECK (SumClicks >= 0)
);
-- =====================================================================
-- 3. LOAD DIMENSIONS
-- =====================================================================
-- New tables are empty by construction; the initial-build guard prevents reruns.

INSERT INTO dw.DimStudent
    (StudentID, Gender, Region, HighestEducation, IMDBand, Disability)
SELECT StudentID, Gender, Region, HighestEducation, IMDBand, Disability
FROM ods.Student;

INSERT INTO dw.DimCourseOffering
    (CourseOfferingCode, ModuleCode, PresentationCode, PresentationLengthDays,
     PresentationYear, PresentationTerm)
SELECT CourseOfferingCode, ModuleCode, PresentationCode, PresentationLengthDays,
       TRY_CONVERT(INT, LEFT(PresentationCode, 4)), RIGHT(PresentationCode, 1)
FROM ods.CourseOffering;

-- Success = PASS or DISTINCTION, at the enrollment level.
INSERT INTO dw.DimFinalResult
    (FinalResultKey, FinalResult, IsSuccess, IsWithdrawn)
VALUES
    (0, 'UNKNOWN',     0, 0),
    (1, 'PASS',        1, 0),
    (2, 'DISTINCTION', 1, 0),
    (3, 'FAIL',        0, 0),
    (4, 'WITHDRAWN',   0, 1);

INSERT INTO dw.DimAssessment (AssessmentID, AssessmentType, AssessmentDay, Weight)
SELECT AssessmentID, AssessmentType, AssessmentDay, Weight
FROM ods.Assessment;

INSERT INTO dw.DimLearningResource (SiteID, ActivityType, WeekFrom, WeekTo)
SELECT SiteID, ActivityType, WeekFrom, WeekTo
FROM ods.LearningResource;

-- DimRelativeDay--

DECLARE @StartDay INT, @EndDay INT;
-- المتغيرات هنا للحصول على أكبر رقم ليوم وكذلك أصغر رقم من جميع الجداول
;WITH DayBounds AS
(
    SELECT MIN(InteractionDay) AS MinDay, MAX(InteractionDay) AS MaxDay
    FROM ods.StudentDailyInteraction
    UNION ALL
    SELECT MIN(SubmittedDay), MAX(SubmittedDay) FROM ods.StudentAssessment
    UNION ALL
    SELECT MIN(AssessmentDay), MAX(AssessmentDay) FROM ods.Assessment
    UNION ALL
    SELECT MIN(RegistrationDay), MAX(RegistrationDay) FROM ods.Enrollment
    UNION ALL
    SELECT MIN(UnregistrationDay), MAX(UnregistrationDay) FROM ods.Enrollment
)
SELECT @StartDay = MIN(MinDay), @EndDay = MAX(MaxDay)
FROM DayBounds;

-- Include day 0 even if no events occurred on that day.
SET @StartDay = CASE WHEN @StartDay IS NULL OR @StartDay > 0 THEN 0 ELSE @StartDay END;
SET @EndDay = CASE WHEN @EndDay IS NULL OR @EndDay < 0 THEN 0 ELSE @EndDay END;

;WITH DayGenerator AS
(
    SELECT CONVERT(BIGINT, @StartDay) AS RelativeDay
    UNION ALL
    SELECT RelativeDay + 1
    FROM DayGenerator
    WHERE RelativeDay < @EndDay
)   -- لتوليد أرقام للأيام حتى أخر يوم ويتضمن الرقم صفر وهناك أيام بالسالب (قبل بدء الدراسة)
INSERT INTO dw.DimRelativeDay
    (RelativeDay, StudyWeekNumber, DayPhase, IsBeforeStart)
SELECT CONVERT(INT, RelativeDay),
       CASE WHEN RelativeDay >= 0 THEN CONVERT(INT, RelativeDay / 7 + 1) ELSE NULL END,  -- رقم الأسبوع
       CASE WHEN RelativeDay < 0 THEN 'Before start'
            WHEN RelativeDay = 0 THEN 'Start day' ELSE 'After start' END,  -- تصنيف اليوم قبل أو بعد بدء الدراسة
       CASE WHEN RelativeDay < 0 THEN 1 ELSE 0 END   -- حالة لو كان قبل البداية
FROM DayGenerator
OPTION (MAXRECURSION 0);   -- To generate more than 100

-- =====================================================================
-- 4. VALIDATE SOURCE LINKS BEFORE LOADING FACTS
-- =====================================================================
-- ODS enrollment uniqueness ensures exactly one enrollment per matched pair.
-- فحص صحة الربط قبل التحميل : هل كل تسليم تقييم وكل تفاعل يخص طالبًا مسجّلًا في نفس المقرر والتقديم؟

IF EXISTS
(
    SELECT 1
    FROM ods.StudentAssessment AS sa
    LEFT JOIN ods.Assessment AS a ON a.AssessmentID = sa.AssessmentID
    LEFT JOIN ods.Enrollment AS e
        ON e.StudentID = sa.StudentID
       AND e.CourseOfferingCode = a.CourseOfferingCode
    WHERE a.AssessmentID IS NULL OR e.EnrollmentID IS NULL
)
    THROW 51003, 'An assessment record has no matching student/course enrollment.', 1;

IF EXISTS
(
    SELECT 1
    FROM ods.StudentDailyInteraction AS i
    LEFT JOIN ods.LearningResource AS r ON r.SiteID = i.SiteID
    LEFT JOIN ods.Enrollment AS e
        ON e.StudentID = i.StudentID
       AND e.CourseOfferingCode = r.CourseOfferingCode
    WHERE r.SiteID IS NULL OR e.EnrollmentID IS NULL
)
    THROW 51004, 'An interaction has no matching resource or student/course enrollment.', 1;


-- =====================================================================
-- 5. LOAD FACT TABLES
-- =====================================================================
/* - A set of variables to verify the completeness of data loading from ODS tables to Fact tables 
by comparing record counts before and after the load -  مقارنة الأعداد قبل التحميل وبعده - */ 

DECLARE @SourceEnrollmentCount BIGINT, @InsertedEnrollmentCount BIGINT;   -- عدد التسجيلات
DECLARE @SourceAssessmentCount BIGINT, @InsertedAssessmentCount BIGINT;   -- عدد تسليمات التقييمات
DECLARE @SourceInteractionCount BIGINT, @InsertedInteractionCount BIGINT; -- عدد صفوف التفاعل
DECLARE @SourceClicks DECIMAL(38,0), @LoadedClicks DECIMAL(38,0);         -- إجمالي النقرات

SELECT @SourceEnrollmentCount = COUNT_BIG(*) 
FROM ods.Enrollment;
SELECT @SourceAssessmentCount = COUNT_BIG(*) 
FROM ods.StudentAssessment;
SELECT @SourceInteractionCount = COUNT_BIG(*), 
       @SourceClicks = COALESCE(SUM(CONVERT(DECIMAL(38,0), SumClicks)), 0) 
FROM ods.StudentDailyInteraction;
-- نراجع عدد الصفوف وإجمالي النقرات معاً لأن عدد الصفوف ممكن يكون صحيحًا، لكن قيم النقرات تكون اتحمّلت بشكل 


-- 5.1 Enrollment --

INSERT INTO dw.FactEnrollment
    (EnrollmentID, StudentID, CourseOfferingCode, FinalResultKey, AgeBand,
     PreviousAttempts, StudiedCredits, RegistrationDay, UnregistrationDay, EnrollmentCount)
SELECT e.EnrollmentID, e.StudentID, e.CourseOfferingCode, fr.FinalResultKey, e.AgeBand, 
       e.PreviousAttempts, e.StudiedCredits, e.RegistrationDay, e.UnregistrationDay, 1
FROM ods.Enrollment AS e
INNER JOIN dw.DimFinalResult AS fr ON fr.FinalResult = COALESCE(e.FinalResult, 'UNKNOWN'); -- لو لم يجد قيمة يرجع Unkown
SET @InsertedEnrollmentCount = ROWCOUNT_BIG();   -- حفظ عدد الصفوف التى تم إدخالها فى المتغير لمقارنة أعداد الصفوف

IF @InsertedEnrollmentCount <> @SourceEnrollmentCount  -- إعطاء خطأ فى حالة عدم التساوى
    THROW 51005, 'Enrollment count mismatch: a classification could not be matched.', 1;


-- 5.2 Student assessment: obtain offering and enrollment context through Assessment --

INSERT INTO dw.FactStudentAssessment
    (StudentAssessmentID, StudentID, CourseOfferingCode,
     FinalResultKey, AssessmentID, SubmittedDay, IsBanked, Score,
     AssessmentRecordCount)
SELECT sa.StudentAssessmentID, sa.StudentID, a.CourseOfferingCode,
       fr.FinalResultKey, sa.AssessmentID, sa.SubmittedDay,
       sa.IsBanked, sa.Score, 1
FROM ods.StudentAssessment AS sa
INNER JOIN ods.Assessment AS a ON a.AssessmentID = sa.AssessmentID             -- a.CourseOfferingCode 
INNER JOIN ods.Enrollment AS e
    ON e.StudentID = sa.StudentID AND e.CourseOfferingCode = a.CourseOfferingCode  -- e.finalResult
INNER JOIN dw.DimFinalResult AS fr ON fr.FinalResult = COALESCE(e.FinalResult, 'UNKNOWN'); -- FK finalresult
SET @InsertedAssessmentCount = ROWCOUNT_BIG();   -- حفظ عدد الصفوف التى تم إدخالها فى المتغير لمقارنة أعداد الصفوف

IF @InsertedAssessmentCount <> @SourceAssessmentCount
    THROW 51006, 'Student assessment count mismatch: some source rows were not loaded.', 1;


-- 5.3 Daily interaction: obtain offering and context through LearningResource --
-- ODS is already aggregated at the target grain. Do NOT aggregate it again.

INSERT INTO dw.FactDailyInteraction
    (InteractionID, StudentID, CourseOfferingCode,
     FinalResultKey, SiteID, InteractionDay, SumClicks)
SELECT i.InteractionID, i.StudentID, r.CourseOfferingCode,
       fr.FinalResultKey, i.SiteID, i.InteractionDay, i.SumClicks
FROM ods.StudentDailyInteraction AS i
INNER JOIN ods.LearningResource AS r ON r.SiteID = i.SiteID       -- r.CourseOfferingCode 
INNER JOIN ods.Enrollment AS e
    ON e.StudentID = i.StudentID AND e.CourseOfferingCode = r.CourseOfferingCode   -- e.finalResult
INNER JOIN dw.DimFinalResult AS fr ON fr.FinalResult = COALESCE(e.FinalResult, 'UNKNOWN');  -- FK finalresult
SET @InsertedInteractionCount = ROWCOUNT_BIG();   -- حفظ عدد الصفوف التى تم إدخالها فى المتغير لمقارنة أعداد الصفوف

IF @InsertedInteractionCount <> @SourceInteractionCount
    THROW 51007, 'Interaction count mismatch: some source rows were not loaded.', 1;


-- =====================================================================
-- 6. VERIFY LOADED COUNTS AND TOTAL CLICKS BEFORE COMMIT
-- =====================================================================
IF (SELECT COUNT_BIG(*) FROM dw.FactEnrollment) <> @SourceEnrollmentCount
 OR (SELECT COUNT_BIG(*) FROM dw.FactStudentAssessment) <> @SourceAssessmentCount
 OR (SELECT COUNT_BIG(*) FROM dw.FactDailyInteraction) <> @SourceInteractionCount
    THROW 51008, 'A DW fact row count does not match ODS.', 1;

IF (SELECT COUNT_BIG(*) FROM dw.DimStudent) <> (SELECT COUNT_BIG(*) FROM ods.Student)
 OR (SELECT COUNT_BIG(*) FROM dw.DimCourseOffering) <> (SELECT COUNT_BIG(*) FROM ods.CourseOffering)
 OR (SELECT COUNT_BIG(*) FROM dw.DimAssessment) <> (SELECT COUNT_BIG(*) FROM ods.Assessment)
 OR (SELECT COUNT_BIG(*) FROM dw.DimLearningResource) <> (SELECT COUNT_BIG(*) FROM ods.LearningResource)
    THROW 51009, 'A source-backed dimension count does not match ODS.', 1;

SELECT @LoadedClicks = COALESCE(SUM(CONVERT(DECIMAL(38,0), SumClicks)), 0)
FROM dw.FactDailyInteraction;
IF @LoadedClicks <> @SourceClicks
    THROW 51010, 'Total clicks changed during DW loading.', 1;

COMMIT TRANSACTION;
PRINT 'OULAD data warehouse created and loaded successfully.';

-- إنشاء إستعلام لمقارنة أعداد الصفوف للجدول  
SELECT
    'Enrollment' AS FactName,
    (SELECT COUNT_BIG(*) FROM ods.Enrollment) AS ODSRows,
    (SELECT COUNT_BIG(*) FROM dw.FactEnrollment) AS DWRows
UNION ALL
SELECT
    'StudentAssessment',
    (SELECT COUNT_BIG(*) FROM ods.StudentAssessment),
    (SELECT COUNT_BIG(*) FROM dw.FactStudentAssessment)
UNION ALL
SELECT
    'DailyInteraction',
    (SELECT COUNT_BIG(*) FROM ods.StudentDailyInteraction),
    (SELECT COUNT_BIG(*) FROM dw.FactDailyInteraction);

-- مقارنة عدد النقرات
SELECT
    src.ODSTotalClicks,
    dwc.DWTotalClicks,
    dwc.DWTotalClicks - src.ODSTotalClicks AS ClickDifference
FROM
(
    SELECT COALESCE(
        SUM(CONVERT(DECIMAL(38,0), SumClicks)), 0
    ) AS ODSTotalClicks
    FROM ods.StudentDailyInteraction
) AS src
CROSS JOIN
(
    SELECT COALESCE(
        SUM(CONVERT(DECIMAL(38,0), SumClicks)), 0
    ) AS DWTotalClicks
    FROM dw.FactDailyInteraction
) AS dwc;

END TRY
/*  التعامل مع الأخطاء التي تحدث داخل BEGIN TRY ... END TRY:
يتراجع عن التغييرات غير المثبّتة، ويعرض تفاصيل الخطأ، ثم يعيد إطلاقه */
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage,
           ERROR_LINE() AS ErrorLine, ERROR_PROCEDURE() AS ErrorProcedure;
    THROW;
END CATCH;
GO

SELECT TOP (10) * FROM dw.FactDailyInteraction;     -- 8,459,320 fields
SELECT * FROM dw.FactStudentAssessment;    -- 173,912 fields
SELECT * FROM dw.FactEnrollment;           -- 32593 fields 
SELECT * FROM dw.DimRelativeDay;           -- 974 fields
SELECT * FROM dw.DimLearningResource;      -- 6,364 fields
SELECT * FROM dw.DimAssessment;            -- 206 fields
SELECT * FROM dw.DimFinalResult;           -- 5 fields
SELECT * FROM dw.DimCourseOffering;        -- 22 fields
SELECT * FROM dw.DimStudent;               -- 28,785 fields
-----------------------------------------------------------------------------------------------
--=============================================================================================
