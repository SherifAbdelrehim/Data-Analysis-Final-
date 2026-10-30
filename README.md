# OULAD — Student Outcomes, Assessment Completion & Learning Engagement

A SQL Server and Python analytics project examining withdrawal, academic failure, assessment completion and learning engagement in the Open University Learning Analytics Dataset (OULAD).

**Study period:** 2013–2014  
**Platforms:** Microsoft SQL Server / T-SQL and Python/pandas  
**Reporting extension:** recommended Microsoft Power BI semantic model  
**Project documentation:** October 2026

## Read this first

| File | Start here for |
|---|---|
| [OULAD_Final_Report_and_Executive_Summary_EN.md](OULAD_Final_Report_and_Executive_Summary_EN.md) | Business problem, verified headline findings, stakeholder-aligned support proposals and analytical limitations. |
| [OULAD_Data_Dictionary_EN.md](OULAD_Data_Dictionary_EN.md) | Source, staging, ODS and DW definitions; SQL types, keys, nullability, analytical features and KPI denominators. |
| [OULAD_Schema_Mapping_and_ERD_EN.md](OULAD_Schema_Mapping_and_ERD_EN.md) | Field-by-field source mapping, normalization, three-fact architecture, ERDs and implementation notes. |
| `Final_OULAD_Analysis(6).ipynb` | Saved validation outputs, analytical calculations, charts and cohort definitions. |
| `OULAD_Stakeholder_Report_Illustrated_EN(1).docx` | Illustrated management report and proposed support for affected groups. |

The Markdown links assume this README and the three documentation files are kept together. SQL, notebook and stakeholder filenames below identify the supplied project files; this README does not itself bundle the source data or create a database backup.

## Project objective

Understand the **withdrawal or academic failure affecting 17,208 of 32,593 enrollments (52.80%)**, and help education managers prioritize support by examining:

- outcomes by module and presentation;
- withdrawal before and during teaching;
- study load, previous attempts and prior education;
- deprivation, region and access needs;
- eligible assessment opportunities, completion, scores and submission timing;
- engagement in the first 28 days and over subsequent study weeks;
- early engagement and assessment submission together.

The unit of analysis is **one student enrollment in one module presentation**. The project covers **28,785 distinct students**, seven modules and 22 presentations. Students can have multiple enrollments.

The analysis describes historical associations. Its exploratory thresholds are not validated individual risk predictions or proven intervention effects.

## Project files and recommended organization

Keep the existing filenames when following this guide. The folders below are a suggested repository organization, not a statement that these folders or a complete packaged repository have already been created.

| Suggested location | Supplied / generated files | Purpose |
|---|---|---|
| Repository root | `README.md` and the three linked OULAD Markdown documents | Project entry point and portable documentation links. |
| `sql/` | `1- OULAD_staging(1).sql` | Database/schema setup, raw staging tables and copies from imported dbo tables. |
| `sql/` | `02_OULAD_clean_views(2).sql` | Seven cleaning views. |
| `sql/` | `Normalization(2).sql` | ODS diagnostics, tables, constraints and loads. |
| `sql/` | `Denromalization(1).sql` | Six dimensions, three facts and load validation. |
| `notebooks/` | `Final_OULAD_Analysis(6).ipynb` | SQL connection, validation, analysis and charts. |
| `docs/` | `OULAD_Stakeholder_Report_Illustrated_EN(1).docx` | Illustrated stakeholder findings and proposed actions. |
| `diagrams/` | `mermaid code.txt`, `Denromalization.txt` | Supplied diagram definitions; reviewed ERDs also appear in the Markdown documentation. |
| `data/` | Seven OULAD CSV files listed below | Required original data; not part of the supplied files reviewed for this documentation task. |
| `power_bi/` | Optional future PBIX/report export | No Power BI file or export was supplied for verification. |

The four SQL files are separate stages. There is no supplied consolidated end-to-end SQL script or separate validation-script package.

## Data architecture

| Layer | Objects | Role |
|---|---|---|
| Source | Seven CSV files initially imported into `dbo.*` | Original course, enrollment, assessment, resource and interaction data. |
| Staging | Seven `stg.raw_*` tables | Imported fields stored as `NVARCHAR(255) NULL` in source-column order. |
| Cleaning | Seven `stg.vw_clean_*` views | Normalize text/missing markers, remove identical normalized rows and safely convert numeric fields. |
| ODS | Seven `ods.*` tables | Typed entities, protected business grains and daily resource-interaction aggregation. |
| Warehouse | Six dimensions and three `dw.*` facts | Separate enrollment, assessment-record and daily-interaction analysis. |
| Python | Eligible populations and enrollment-level summaries | Validation, expected assessment opportunities, engagement windows and stakeholder findings. |
| Power BI | Recommended semantic model | Reporting design documented; dashboard implementation not verified. |

### Main warehouse tables

| Table | Purpose | Grain | Recorded rows |
|---|---|---|---:|
| `dw.DimStudent` | Stable student profile | One student | 28,785 |
| `dw.DimCourseOffering` | Module presentation, duration, year and term | One module presentation | 22 |
| `dw.DimFinalResult` | Outcome labels and flags, including UNKNOWN | One outcome member | 5 |
| `dw.DimAssessment` | Assessment type, deadline and weight | One assessment | 206 |
| `dw.DimLearningResource` | Activity type and availability weeks | One resource | 6,364 |
| `dw.DimRelativeDay` | Signed day offset and study-week attributes | One relative day | 974 |
| `dw.FactEnrollment` | Outcomes, load, attempts, age band and registration timing | One student × offering | 32,593 |
| `dw.FactStudentAssessment` | Current and banked assessment records | One student × assessment | 173,912 |
| `dw.FactDailyInteraction` | Retained clicks aggregated by resource/day | One student × resource × relative day | 8,459,320 |

Counts come from saved notebook outputs. They are not newly executed source-file counts. Fact business keys are protected by UNIQUE constraints in addition to their row identifiers.

## Requirements

- Microsoft SQL Server and a SQL client such as SQL Server Management Studio.
- A Python environment with Jupyter support.
- pandas, NumPy, Matplotlib, seaborn, SQLAlchemy, pyodbc, Jinja2 and ipywidgets.
- Microsoft ODBC Driver 18 for SQL Server, matching the notebook's connection configuration.
- Access to the seven original CSV files or an existing correctly populated OULAD database.
- Sufficient memory for the supplied notebook: its initial table-loading step reads all nine warehouse tables, including the interaction fact. Later SQL aggregations do not remove that initial memory requirement.

For a new Python environment, install the notebook dependencies with a command such as:

```bash
python -m pip install pandas numpy matplotlib seaborn sqlalchemy pyodbc jinja2 ipywidgets jupyterlab
```

This is an unpinned dependency list based on the notebook imports, not a tested version lock. The ODBC driver is a separate system installation. A standalone verified `requirements.txt` was not supplied with the reviewed files.

## How to run the project

### 1. Prepare the database and original data

If starting from CSV files, create the `OULAD` database using the database-setup section of `1- OULAD_staging(1).sql`, then import these files into that database as the corresponding dbo tables:

| CSV | Initially imported table |
|---|---|
| `courses.csv` | `dbo.courses` |
| `assessments.csv` | `dbo.assessments` |
| `vle.csv` | `dbo.vle` |
| `studentInfo.csv` | `dbo.studentInfo` |
| `studentRegistration.csv` | `dbo.studentRegistration` |
| `studentAssessment.csv` | `dbo.studentAssessment` |
| `studentVle.csv` | `dbo.studentVle` |

Preserve the original column names, order and source values during import. The supplied staging file **copies from dbo tables**; it does not contain CSV BULK INSERT commands. If the database already exists, skip its initial creation statement and inspect the existing objects before continuing.

### 2. Run the four SQL stages in order

| Order | File / section | What to verify |
|---:|---|---|
| 1 | Remaining staging sections in `1- OULAD_staging(1).sql` | Create seven raw tables and copy dbo values; reconcile source/staging counts before source cleanup. |
| 2 | `02_OULAD_clean_views(2).sql` | Create seven views; inspect conversion failures and conflicting business-key records. |
| 3 | `Normalization(2).sql` | Review source/profile diagnostics; build and load seven ODS tables; check keys and relationships. |
| 4 | `Denromalization(1).sql` | Build six dimensions and three facts; verify ODS-to-DW counts and total clicks. |

**Execution details:**

- The staging file contains active `DROP TABLE dbo.*` statements after copying. Review that cleanup section and validate the copies before running it. The staging inserts and drops are not wrapped in one encompassing transaction.
- Raw copies use `SELECT *`, so column order matters. Several diagnostic queries also return full tables rather than small previews.
- ODS explicitly stops if a target table already exists and rejects nonempty loads. DW creates its targets inside a transaction and fails when those targets already exist. These are initial-build scripts, not incremental refresh/upsert scripts.
- Keep optional commented reset statements separate from normal execution. A failure in a later ODS entity load does not undo previously committed entity loads.

### 3. Configure the notebook connection

Open `Final_OULAD_Analysis(6).ipynb` in Jupyter or VS Code. Select the Python environment containing the dependencies and replace the connection's machine-specific values with your own SQL Server settings. For the existing Windows-authentication approach:

```python
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

server_name = r"YOUR_SQL_SERVER_INSTANCE"
database_name = "OULAD"

connection_string = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    f"SERVER={server_name};"
    f"DATABASE={database_name};"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

engine = create_engine(
    URL.create("mssql+pyodbc", query={"odbc_connect": connection_string})
)
```

This mirrors the supplied local connection pattern. Use the authentication and certificate settings appropriate to your own SQL Server connection.

### 4. Run validation and analysis

Run the connection test, warehouse loading, key checks, foreign-key checks and protected dimension merges before the analytical sections. Stop and investigate if validation fails or a join changes the enrollment grain.

Then run the notebook sections in order:

1. Student outcomes, success and withdrawal.
2. Expected assessment opportunities, submission and final outcomes.
3. Early and weekly learning engagement.
4. Joint early engagement × assessment submission.

The saved notebook has pip installation messages with `Invalid requirement: '#'` in two dependency cells containing inline comments. Install Jinja2/ipywidgets using clean commands without trailing comments, or skip those installation cells once dependencies are installed. Update the machine-specific requirements-export path near the end before executing it. Saved analytical outputs are available, but a clean full rerun was not performed while preparing these documents.

### 5. Share the work

For review, share the notebook with its outputs, the SQL scripts, the three documentation files and the stakeholder report. For independent execution, also provide access to the original CSV files or a usable database backup, the intended environment dependencies and local connection instructions. A notebook alone does not contain the SQL Server data.

## Power BI relationship design

Use one-to-many relationships with **single-direction filtering from dimension to fact**:

| Dimension | Fact relationship(s) |
|---|---|
| `DimStudent[StudentID]` | StudentID in all three facts |
| `DimCourseOffering[CourseOfferingCode]` | CourseOfferingCode in all three facts |
| `DimFinalResult[FinalResultKey]` | FinalResultKey in all three facts |
| `DimAssessment[AssessmentID]` | FactStudentAssessment[AssessmentID] |
| `DimLearningResource[SiteID]` | FactDailyInteraction[SiteID] |
| `DimRelativeDay[RelativeDay]` | FactDailyInteraction[InteractionDay] |

These represent 12 declared DW foreign keys. The relationship recommendations do not verify any existing PBIX configuration.

Keep overall outcome measures on FactEnrollment. Do not join detailed facts directly. Aggregate assessment and interaction measures to StudentID + CourseOfferingCode before combining them.

AgeBand, StudiedCredits and PreviousAttempts are enrollment-fact attributes; they do not automatically filter behavioral facts under this single-direction design. Transfer the selected enrollment population explicitly in measures or prepare an enrollment-grain semantic table. The data dictionary explains the design options.

Expected-assessment measures also need the full assessment-to-offering catalog: DimAssessment omits CourseOfferingCode, and the notebook recovers it through `ods.Assessment`. Observed submission records alone cannot represent missing expected submissions.

## Headline numbers

| Indicator | Result |
|---|---:|
| Enrollments / distinct students | 32,593 / 28,785 |
| Successful enrollments, PASS + DISTINCTION | 15,385 (47.20%) |
| Withdrawals | 10,156 (31.16%) |
| Failures | 7,052 (21.64%) |
| Combined withdrawal and failure | **17,208 (52.80%)** |
| CCC / DDD combined rate | 62.16% / 58.39% |
| BBB / FFF affected enrollments | 4,155 / 4,114 |
| GGG failure rate | 28.73% |
| Withdrawals before the end of the first four weeks, including before teaching | 49.55% of all withdrawals |
| Combined rate above 120 studied credits | 69.64% |
| Combined rate with previous attempts / without | 66.92% / 50.72% |
| Eligible current requirements without a submission record | 22.93%, excluding banked requirements |
| Joint-analysis success: High engagement / High submission | 69.35% |
| Joint-analysis success: High engagement / Low submission | 22.82% |
| Joint-analysis success: Low engagement / High submission | 50.27% |
| Joint-analysis success: Low engagement / Low submission | 10.83% |

Joint results cover **21,533 eligible enrollments in five modules**, not the full dataset. See the final report for cohort definitions, supporting comparisons and proposed support actions.

## Recommended Power BI pages

1. **Executive Overview** — enrollment/student totals, outcomes and module rates alongside affected counts.
2. **Outcomes & Support Needs** — module/presentation, workload, previous attempts, education, deprivation and region.
3. **Withdrawal Timing** — pre-start, early, later and unknown timing, with clear denominators.
4. **Assessment Completion** — eligible requirements, missing records, completion, scores and timing.
5. **Early & Weekly Engagement** — clicks, active days and eligible/measured population counts.
6. **Engagement × Submission** — the four early groups, coverage, exploratory definitions and support proposals.

These pages are recommendations derived from the completed Python analysis; no dashboard implementation is included in the verified evidence.

## Final validation targets

| Check | Target / recorded evidence |
|---|---|
| Enrollment / student counts | 32,593 / 28,785 in saved outputs |
| Assessment / interaction fact counts | 173,912 / 8,459,320 in saved outputs |
| Key checks | All 14 inspected combinations PASS |
| Declared DW foreign keys | All 12 checked relationships PASS; zero null-key and orphan rows |
| Enrollment dimension merges | 32,593 rows retained; zero unmatched rows for each of three joins |
| Outcome reconciliation | 12,361 PASS + 3,024 DISTINCTION + 7,052 FAIL + 10,156 WITHDRAWN = 32,593 |
| ODS-to-DW counts | Three fact counts and source-backed dimension counts must match; enforced in the DW script |
| ODS-to-DW total clicks | Difference must be zero; enforced in the DW script |
| Fact counters | EnrollmentCount = 1; AssessmentRecordCount = 1 |
| Full-window early engagement | 27,229 eligible = 26,754 measured + 475 without interaction records |
| Joint cohort | 10,567 + 241 + 8,730 + 1,995 = 21,533 |
| Missing-record denominator | 49,214 / 214,627 eligible current requirements = 22.93% |

Saved ODS-to-DW reconciliation query results and raw-to-clean interaction reconciliation results were not supplied separately. Implemented controls are not a substitute for retained execution evidence.

## Important analytical limitations

- Student, enrollment, assessment-record and interaction grains are different. Mixing them can inflate counts and measures.
- Full-window early analysis excludes early withdrawals; joint analysis also requires early assessment opportunities and valid timing. Do not generalize either selected population to all enrollments.
- No interaction record is not automatically zero activity. Missing submission records require a completeness check; banked records are not current submissions.
- Weekly eligible samples change with course timing and withdrawal. A weekly group trend does not track an unchanged set of students.
- Relative days are not calendar dates. Day 0 is the course start, and negative values are valid pre-start offsets.
- Cleaning removes identical normalized rows before interaction aggregation. Without raw-to-clean reconciliation, original raw click preservation cannot be claimed.
- Small segments and overlapping factors limit interpretation. Always show counts beside rates and treat findings as associations.
- Final outcome keys on behavioral facts support retrospective analysis; they must not be used as predictor inputs for a prospective early-support model.

## Technology stack

- Microsoft SQL Server, T-SQL and SQL Server Management Studio.
- Python, pandas and NumPy for analytical preparation and validation.
- SQLAlchemy, pyodbc and ODBC Driver 18 for database connectivity.
- Matplotlib and seaborn for charts; Jinja2 and ipywidgets for notebook presentation.
- Jupyter / VS Code for notebook execution.
- Markdown and Mermaid for documentation and ERDs.
- Microsoft Power BI, Power Query and DAX as the recommended reporting extension.

## Project outcome

The project provides a structured path from seven source datasets to validated warehouse analysis and stakeholder support proposals. Its priorities are targeted module support, manageable study loads, help for repeat attempts, stronger preparation and access, and joint monitoring of assessment completion and engagement. Proposed actions should be piloted and evaluated through completion, retention and success within comparable module presentations before expansion.
