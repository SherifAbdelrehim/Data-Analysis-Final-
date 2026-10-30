-- =======================================================================
-- OULAD - PHASE 2: CLEANING & MAPPING VIEWS
-- =======================================================================

USE OULAD;
GO
--=============================================================

-- 1. Clean courses

CREATE OR ALTER VIEW stg.vw_clean_courses
AS
WITH CleanedText AS
(
    SELECT
        UPPER(TRIM(code_module)) AS code_module,
        UPPER(TRIM(code_presentation)) AS code_presentation,
        UPPER(TRIM(module_presentation_length)) AS module_presentation_length
    FROM stg.raw_courses
),
NormalizedData AS
(
    SELECT
        CASE
            WHEN code_module IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_module
        END AS code_module,

        CASE
            WHEN code_presentation IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_presentation
        END AS code_presentation,

        CASE
            WHEN module_presentation_length IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE module_presentation_length
        END AS module_presentation_length

    FROM CleanedText
),
DeduplicatedData AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY code_module, code_presentation, module_presentation_length
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM NormalizedData
),
TypedData AS
(
    SELECT
        code_module,
        code_presentation,
        module_presentation_length,
        TRY_CAST(module_presentation_length AS INT) AS Parsed_module_presentation_length
    FROM DeduplicatedData
    WHERE rn = 1
)
SELECT
    code_module,
    code_presentation,
    CASE 
        WHEN Parsed_module_presentation_length > 0 
        THEN Parsed_module_presentation_length 
        ELSE NULL 
    END AS module_presentation_length
FROM TypedData;
GO
--=============================================================

-- 2. Clean assessments

CREATE OR ALTER VIEW stg.vw_clean_assessments
AS
WITH CleanedText AS
(
    SELECT
        UPPER(TRIM(code_module)) AS code_module,
        UPPER(TRIM(code_presentation)) AS code_presentation,
        UPPER(TRIM(id_assessment)) AS id_assessment,
        UPPER(TRIM(assessment_type)) AS assessment_type,
        UPPER(TRIM(date)) AS date,
        UPPER(TRIM(weight)) AS weight
    FROM stg.raw_assessments
),
NormalizedData AS
(
    SELECT
        CASE
            WHEN code_module IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_module
        END AS code_module,

        CASE
            WHEN code_presentation IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_presentation
        END AS code_presentation,

        CASE
            WHEN id_assessment IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE id_assessment
        END AS id_assessment,

        CASE
            WHEN assessment_type IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE assessment_type
        END AS assessment_type,

        CASE
            WHEN date IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE date
        END AS date,

        CASE
            WHEN weight IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE weight
        END AS weight

    FROM CleanedText
),
DeduplicatedData AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY code_module, code_presentation, id_assessment, assessment_type, date, weight
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM NormalizedData
),
TypedData AS
(
    SELECT
        code_module,
        code_presentation,
        id_assessment,
        TRY_CAST(id_assessment AS INT) AS Parsed_id_assessment,
        assessment_type,
        date,
        TRY_CAST(date AS INT) AS Parsed_date,
        weight,
        TRY_CAST(weight AS DECIMAL(6,2)) AS Parsed_weight
    FROM DeduplicatedData
    WHERE rn = 1
)
SELECT
    code_module,
    code_presentation,
    CASE WHEN Parsed_id_assessment > 0 THEN Parsed_id_assessment ELSE NULL END AS id_assessment,
    assessment_type,
    Parsed_date AS date,
    CASE WHEN Parsed_weight BETWEEN 0 AND 100 THEN Parsed_weight ELSE NULL END AS weight
FROM TypedData;
GO
--=============================================================

-- 3. Clean vle

CREATE OR ALTER VIEW stg.vw_clean_vle
AS
WITH CleanedText AS
(
    SELECT
        UPPER(TRIM(id_site)) AS id_site,
        UPPER(TRIM(code_module)) AS code_module,
        UPPER(TRIM(code_presentation)) AS code_presentation,
        UPPER(TRIM(activity_type)) AS activity_type,
        UPPER(TRIM(week_from)) AS week_from,
        UPPER(TRIM(week_to)) AS week_to
    FROM stg.raw_vle
),
NormalizedData AS
(
    SELECT
        CASE
            WHEN id_site IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE id_site
        END AS id_site,

        CASE
            WHEN code_module IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_module
        END AS code_module,

        CASE
            WHEN code_presentation IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_presentation
        END AS code_presentation,

        CASE
            WHEN activity_type IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE activity_type
        END AS activity_type,

        CASE
            WHEN week_from IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE week_from
        END AS week_from,

        CASE
            WHEN week_to IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE week_to
        END AS week_to

    FROM CleanedText
),
DeduplicatedData AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY id_site, code_module, code_presentation, activity_type, week_from, week_to
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM NormalizedData
),
TypedData AS
(
    SELECT
        id_site,
        TRY_CAST(id_site AS INT) AS Parsed_id_site,
        code_module,
        code_presentation,
        activity_type,
        week_from,
        TRY_CAST(week_from AS INT) AS Parsed_week_from,
        week_to,
        TRY_CAST(week_to AS INT) AS Parsed_week_to
    FROM DeduplicatedData
    WHERE rn = 1
)
SELECT
    CASE WHEN Parsed_id_site > 0 THEN Parsed_id_site ELSE NULL END AS id_site,
    code_module,
    code_presentation,
    activity_type,
    Parsed_week_from AS week_from,
    Parsed_week_to AS week_to
FROM TypedData;
GO
--=============================================================

-- 4. Clean studentInfo

CREATE OR ALTER VIEW stg.vw_clean_studentInfo
AS
WITH CleanedText AS
(
    SELECT
        UPPER(TRIM(code_module)) AS code_module,
        UPPER(TRIM(code_presentation)) AS code_presentation,
        UPPER(TRIM(id_student)) AS id_student,
        UPPER(TRIM(gender)) AS gender,
        UPPER(TRIM(region)) AS region,
        UPPER(TRIM(highest_education)) AS highest_education,
        UPPER(TRIM(imd_band)) AS imd_band,
        UPPER(TRIM(age_band)) AS age_band,
        UPPER(TRIM(num_of_prev_attempts)) AS num_of_prev_attempts,
        UPPER(TRIM(studied_credits)) AS studied_credits,
        UPPER(TRIM(disability)) AS disability,
        UPPER(TRIM(final_result)) AS final_result
    FROM stg.raw_studentInfo
),
NormalizedData AS
(
    SELECT
        CASE
            WHEN code_module IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_module
        END AS code_module,

        CASE
            WHEN code_presentation IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_presentation
        END AS code_presentation,

        CASE
            WHEN id_student IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE id_student
        END AS id_student,

        CASE
            WHEN gender IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE gender
        END AS gender,

        CASE
            WHEN region IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE region
        END AS region,

        CASE
            WHEN highest_education IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE highest_education
        END AS highest_education,

        CASE
            WHEN imd_band IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE imd_band
        END AS imd_band,

        CASE
            WHEN age_band IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE age_band
        END AS age_band,

        CASE
            WHEN num_of_prev_attempts IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE num_of_prev_attempts
        END AS num_of_prev_attempts,

        CASE
            WHEN studied_credits IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE studied_credits
        END AS studied_credits,

        CASE
            WHEN disability IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE disability
        END AS disability,

        CASE
            WHEN final_result IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE final_result
        END AS final_result

    FROM CleanedText
),
DeduplicatedData AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY code_module, code_presentation, id_student, gender, region, highest_education, imd_band, age_band, num_of_prev_attempts, studied_credits, disability, final_result
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM NormalizedData
),
TypedData AS
(
    SELECT
        code_module,
        code_presentation,
        id_student,
        TRY_CAST(id_student AS INT) AS Parsed_id_student,
        gender,
        region,
        highest_education,
        imd_band,
        age_band,
        num_of_prev_attempts,
        TRY_CAST(num_of_prev_attempts AS INT) AS Parsed_num_of_prev_attempts,
        studied_credits,
        TRY_CAST(studied_credits AS INT) AS Parsed_studied_credits,
        disability,
        final_result
    FROM DeduplicatedData
    WHERE rn = 1
)
SELECT
    code_module,
    code_presentation,
    CASE WHEN Parsed_id_student > 0 THEN Parsed_id_student ELSE NULL END AS id_student,
    gender,
    region,
    highest_education,
    imd_band,
    age_band,
    CASE WHEN Parsed_num_of_prev_attempts >= 0 THEN Parsed_num_of_prev_attempts ELSE NULL END AS num_of_prev_attempts,
    CASE WHEN Parsed_studied_credits >= 0 THEN Parsed_studied_credits ELSE NULL END AS studied_credits,
    disability,
    final_result
FROM TypedData;
GO
--=============================================================

-- 5. Clean studentRegistration

CREATE OR ALTER VIEW stg.vw_clean_studentRegistration
AS
WITH CleanedText AS
(
    SELECT
        UPPER(TRIM(code_module)) AS code_module,
        UPPER(TRIM(code_presentation)) AS code_presentation,
        UPPER(TRIM(id_student)) AS id_student,
        UPPER(TRIM(date_registration)) AS date_registration,
        UPPER(TRIM(date_unregistration)) AS date_unregistration
    FROM stg.raw_studentRegistration
),
NormalizedData AS
(
    SELECT
        CASE
            WHEN code_module IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_module
        END AS code_module,

        CASE
            WHEN code_presentation IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE code_presentation
        END AS code_presentation,

        CASE
            WHEN id_student IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE id_student
        END AS id_student,

        CASE
            WHEN date_registration IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE date_registration
        END AS date_registration,

        CASE
            WHEN date_unregistration IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE date_unregistration
        END AS date_unregistration

    FROM CleanedText
),
DeduplicatedData AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY code_module, code_presentation, id_student, date_registration, date_unregistration
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM NormalizedData
),
TypedData AS
(
    SELECT
        code_module,
        code_presentation,
        id_student,
        TRY_CAST(id_student AS INT) AS Parsed_id_student,
        date_registration,
        TRY_CAST(date_registration AS INT) AS Parsed_date_registration,
        date_unregistration,
        TRY_CAST(date_unregistration AS INT) AS Parsed_date_unregistration
    FROM DeduplicatedData
    WHERE rn = 1
)
SELECT
    code_module,
    code_presentation,
    CASE WHEN Parsed_id_student > 0 THEN Parsed_id_student ELSE NULL END AS id_student,
    Parsed_date_registration AS date_registration,
    Parsed_date_unregistration AS date_unregistration
FROM TypedData;
GO
--=============================================================

-- 6. Clean studentAssessment

CREATE OR ALTER VIEW stg.vw_clean_studentAssessment
AS
WITH CleanedText AS
(
    SELECT
        UPPER(TRIM(id_assessment)) AS id_assessment,
        UPPER(TRIM(id_student)) AS id_student,
        UPPER(TRIM(date_submitted)) AS date_submitted,
        UPPER(TRIM(is_banked)) AS is_banked,
        UPPER(TRIM(score)) AS score
    FROM stg.raw_studentAssessment
),
NormalizedData AS
(
    SELECT
        CASE
            WHEN id_assessment IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE id_assessment
        END AS id_assessment,

        CASE
            WHEN id_student IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE id_student
        END AS id_student,

        CASE
            WHEN date_submitted IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE date_submitted
        END AS date_submitted,

        CASE
            WHEN is_banked IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE is_banked
        END AS is_banked,

        CASE
            WHEN score IN ('', '?', 'NULL', 'N/A')
            THEN NULL
            ELSE score
        END AS score

    FROM CleanedText
),
DeduplicatedData AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY id_assessment, id_student, date_submitted, is_banked, score
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM NormalizedData
),
TypedData AS
(
    SELECT
        id_assessment,
        TRY_CAST(id_assessment AS INT) AS Parsed_id_assessment,
        id_student,
        TRY_CAST(id_student AS INT) AS Parsed_id_student,
        date_submitted,
        TRY_CAST(date_submitted AS INT) AS Parsed_date_submitted,
        is_banked,
        TRY_CAST(is_banked AS INT) AS Parsed_is_banked,
        score,
        TRY_CAST(score AS DECIMAL(6,2)) AS Parsed_score
    FROM DeduplicatedData
    WHERE rn = 1
)
SELECT
    CASE WHEN Parsed_id_assessment > 0 THEN Parsed_id_assessment ELSE NULL END AS id_assessment,
    CASE WHEN Parsed_id_student > 0 THEN Parsed_id_student ELSE NULL END AS id_student,
    Parsed_date_submitted AS date_submitted,
    CASE WHEN Parsed_is_banked IN (0, 1) THEN Parsed_is_banked ELSE NULL END AS is_banked,
    CASE WHEN Parsed_score BETWEEN 0 AND 100 THEN Parsed_score ELSE NULL END AS score
FROM TypedData;
GO
--=============================================================

-- 7. Clean studentVle

CREATE OR ALTER VIEW stg.vw_clean_studentVle
AS
WITH CleanedText AS
(
    SELECT
        UPPER(TRIM(code_module)) AS code_module,
        UPPER(TRIM(code_presentation)) AS code_presentation,
        UPPER(TRIM(id_student)) AS id_student,
        UPPER(TRIM(id_site)) AS id_site,
        UPPER(TRIM(date)) AS date,
        UPPER(TRIM(sum_click)) AS sum_click
    FROM stg.raw_studentVle
),
NormalizedData AS
(
    SELECT
        CASE WHEN code_module IN ('', '?', 'NULL', 'N/A')
             THEN NULL ELSE code_module END AS code_module,

        CASE WHEN code_presentation IN ('', '?', 'NULL', 'N/A')
             THEN NULL ELSE code_presentation END AS code_presentation,

        CASE WHEN id_student IN ('', '?', 'NULL', 'N/A')
             THEN NULL ELSE id_student END AS id_student,

        CASE WHEN id_site IN ('', '?', 'NULL', 'N/A')
             THEN NULL ELSE id_site END AS id_site,

        CASE WHEN date IN ('', '?', 'NULL', 'N/A')
             THEN NULL ELSE date END AS date,

        CASE WHEN sum_click IN ('', '?', 'NULL', 'N/A')
             THEN NULL ELSE sum_click END AS sum_click
    FROM CleanedText
),
DeduplicatedData AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY code_module, code_presentation, id_student, id_site, date, sum_click
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM NormalizedData
),
TypedData AS
(
    SELECT
        code_module,
        code_presentation,
        id_student,
        TRY_CAST(id_student AS INT) AS Parsed_id_student,
        id_site,
        TRY_CAST(id_site AS INT) AS Parsed_id_site,
        date,
        TRY_CAST(date AS INT) AS Parsed_date,
        sum_click,
        TRY_CAST(sum_click AS BIGINT) AS Parsed_sum_click
    FROM DeduplicatedData
    WHERE rn = 1
)
SELECT
    code_module,
    code_presentation,
    CASE WHEN Parsed_id_student > 0 THEN Parsed_id_student ELSE NULL END AS id_student,
    CASE WHEN Parsed_id_site > 0 THEN Parsed_id_site ELSE NULL END AS id_site,
    Parsed_date AS date,
    CASE WHEN Parsed_sum_click >= 0 THEN Parsed_sum_click ELSE NULL END AS sum_click
FROM TypedData;
GO

-- =======================================================================
-- These queries are commented out; view creation does not scan the 10M+ rows.
-- =======================================================================

SELECT * FROM stg.vw_clean_courses;
SELECT * FROM stg.vw_clean_assessments;
SELECT TOP (10) * FROM stg.vw_clean_vle;
SELECT TOP (10) * FROM stg.vw_clean_studentInfo;
SELECT TOP (10) * FROM stg.vw_clean_studentRegistration;
SELECT TOP (10) * FROM stg.vw_clean_studentAssessment;
SELECT TOP (10) * FROM stg.vw_clean_studentVle;



