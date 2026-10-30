# OULAD — Final Report & Executive Summary

**Project:** Student Outcomes, Assessment Completion and Learning Engagement  
**Reporting date:** 28 October 2026  
**Study period:** 2013–2014  
**Evidence:** Supplied SQL scripts, saved analysis-notebook outputs and the final illustrated stakeholder report.

## Executive Summary

This project transforms seven Open University Learning Analytics Dataset (OULAD) source files into a SQL Server analytical warehouse and a Python analysis of student outcomes, assessment completion and learning engagement. The implemented workflow covers **Staging → Cleaning & Standardization → Normalized ODS → Dimensional Modeling → Validation & Analytical Preparation → Analysis & Stakeholder Reporting**.

**The business problem is that more than half of enrollments ended in withdrawal or academic failure:** **17,208 of 32,593 enrollments (52.80%)**. Withdrawal accounted for **31.16%** and failure for **21.64%**. Overall success, combining PASS and DISTINCTION, was **47.20%**. The analysis covers **28,785 distinct students**, **7 modules** and **22 module presentations**.

The objective is to identify where support is most needed and how registration, study load, previous attempts, academic preparation, assessment completion and learning engagement can inform that support. Findings describe historical associations; they do not establish causes or validate an individual prediction system.

**Headline findings:**

- **Module priorities:** CCC and DDD had the highest combined withdrawal and failure rates, at **62.16%** and **58.39%**. BBB and FFF had the largest affected populations, with **4,155** and **4,114** enrollments respectively. GGG had the highest failure rate, **28.73%**, despite relatively low withdrawal.
- **Timing:** **49.55% of withdrawals** occurred before the end of the first four weeks, including withdrawals before teaching began. Support is needed before entry, during the first month and throughout the remaining course.
- **Study load:** combined withdrawal and failure increased from **48.20%** at 1–60 studied credits to **69.64%** above 120 credits, mainly through higher withdrawal.
- **Previous attempts:** the combined rate was **66.92%** among enrollments with previous attempts, compared with **50.72%** among those without.
- **Preparation and access:** the combined rate was **70.32%** among enrollments with no formal qualifications. It was **64.84%** in the most deprived IMD band versus **42.47%** in the least deprived band.
- **Assessment completion:** **22.93% of eligible current TMA/CMA assessment requirements had no submission record**. Average completion per enrollment was **43.67%** for FAIL and **58.17%** for WITHDRAWN, compared with **95.52%** for PASS and **96.68%** for DISTINCTION.
- **Early engagement:** among enrollments eligible throughout days 0–27 with interaction records, median active days were **11** for PASS and **14** for DISTINCTION, versus **7** for FAIL and **8** for WITHDRAWN.
- **Engagement and submission together:** success was **69.35%** when both were high, **22.82%** with high engagement and low submission, **50.27%** with low engagement and high submission, and **10.83%** when both were low. This comparison covers **21,533 eligible enrollments in five modules**.

**Recommendation priorities, aligned with the stakeholder report:** focus support on CCC and DDD; provide capacity for case volumes in BBB and FFF; address academic performance in GGG; review high study loads and previous attempts; strengthen preparation and access; and monitor assessment submission alongside early and weekly engagement. Pilot support actions and evaluate completion, retention and success within comparable module presentations before expansion.

---

## 1. Objective & Scope

### 1.1 Business problem and objective

The central problem is **withdrawal and academic failure affecting 52.80% of enrollments**. The business objective is to help education managers and student-support teams identify affected groups, understand differences in support needs and prioritize practical assistance.

Withdrawal and failure require related but distinct responses. Retention support addresses difficulties continuing study; academic support addresses difficulties achieving the required standard. A combined indicator provides an overall management view, while separate outcome measures guide the response.

### 1.2 Analytical scope

The report covers:

- overall and module-presentation outcomes;
- withdrawal timing before and during teaching;
- study load and previous attempts at the same module;
- prior education, deprivation and regional differences;
- expected assessment opportunities, completion, timing and recorded scores;
- early engagement during days 0–27 and weekly engagement;
- the joint relationship of early engagement and assessment submission with final outcomes;
- data quality, analytical grain, eligibility rules and reporting limitations.

**Unit of analysis:** one student enrollment in one specific module presentation. A student may have more than one enrollment; **32,593 enrollments must not be described as 32,593 distinct students**.

### 1.3 Source files

| Source | Purpose |
|---|---|
| `courses.csv` | Module presentations and presentation length |
| `studentInfo.csv` | Enrollment outcomes, student characteristics, study load and previous attempts |
| `studentRegistration.csv` | Registration and unregistration relative days |
| `assessments.csv` | Assessment type, due day and weight |
| `studentAssessment.csv` | Submission records, banked status and scores |
| `vle.csv` | Learning-resource identifiers and activity types |
| `studentVle.csv` | Recorded clicks by student, resource and relative day |

## 2. Method — the Six Stages

| Stage | What it does | Evidence / deliverable |
|---|---|---|
| 1. Staging | Creates the database staging layer and imports the seven source files as text | `1- OULAD_staging(1).sql` |
| 2. Cleaning & Standardization | Trims text, normalizes missing markers and categories, safely converts types, and applies deduplication rules | `02_OULAD_clean_views(2).sql` |
| 3. Normalized ODS | Separates students, course offerings, enrollments, assessments, submissions, resources and daily interactions; defines keys and constraints | `Normalization(2).sql` and `mermaid code.txt` |
| 4. Dimensional Modeling | Builds six dimensions and three facts for outcomes, submissions and interactions | `Denromalization(1).sql` and `Denromalization.txt` |
| 5. Validation & Analytical Preparation | Checks warehouse keys and relationships, protects merge cardinality and constructs eligible assessment and engagement populations | Saved outputs in `Final_OULAD_Analysis(6).ipynb` |
| 6. Analysis & Stakeholder Reporting | Calculates KPIs, compares outcomes and behavior, and links results to support proposals | Notebook outputs and `OULAD_Stakeholder_Report_Illustrated_EN(1).docx` |

### 2.1 Fact-table grains

| Fact table | Grain | Use |
|---|---|---|
| `dw.FactEnrollment` | One student × course offering | Enrollment counts, final outcomes, study load, previous attempts and registration timing |
| `dw.FactStudentAssessment` | One student × assessment, including banked records | Submission timing, recorded scores and assessment-record analysis |
| `dw.FactDailyInteraction` | One student × learning resource × relative day | Click totals and engagement measures |

Each resource maps to a course offering. The interaction fact also carries `CourseOfferingCode`; its declared unique grain is `(StudentID, SiteID, InteractionDay)`.

### 2.2 Measures and denominator rules

| Measure | Definition / denominator |
|---|---|
| Success rate | PASS + DISTINCTION enrollments / enrollments with known outcomes in the selected population |
| Withdrawal rate | WITHDRAWN enrollments / enrollments with known outcomes in the selected population |
| Failure rate | FAIL enrollments / enrollments with known outcomes in the selected population |
| Combined withdrawal and failure rate | WITHDRAWN + FAIL enrollments / enrollments with known outcomes in the selected population |
| Share of withdrawals by timing | Withdrawals in the specified period / all 10,156 withdrawals |
| Missing submission-record share | Eligible TMA/CMA opportunities without a matching submission record / eligible current requirements (current submissions + no-record opportunities), excluding banked records |
| Mean completion per enrollment | Calculate current-submission completion for each enrollment, excluding banked requirements, then average across enrollments with at least one eligible requirement |
| On-time rate among timed submissions | On-time or early current submissions / eligible current submissions with usable timing |
| Early active days | Distinct days with positive clicks during days 0–27, within the eligible measured population |

All 32,593 enrollments have known outcomes in the saved analysis. Combined percentages are calculated from counts; summing rounded outcome percentages can give a slightly different result.

## 3. Data Quality & Modeling Results

### 3.1 Verified warehouse profile

The following values are recorded in the supplied notebook's saved outputs. They are warehouse counts, not a fresh count of the original CSV files.

| Warehouse table | Rows |
|---|---:|
| `dw.DimStudent` | 28,785 |
| `dw.DimCourseOffering` | 22 |
| `dw.DimFinalResult` | 5 |
| `dw.DimAssessment` | 206 |
| `dw.DimLearningResource` | 6,364 |
| `dw.DimRelativeDay` | 974 |
| `dw.FactEnrollment` | 32,593 |
| `dw.FactStudentAssessment` | 173,912 |
| `dw.FactDailyInteraction` | 8,459,320 |

`DimFinalResult` contains an UNKNOWN member in addition to the four substantive outcomes. No enrollment was classified as unknown in the analysis.

### 3.2 Recorded validation results

- **14 inspected key combinations across 9 tables passed** missing-value and duplication checks.
- **12 declared foreign-key relationships passed**, with zero null-key rows and zero orphan rows in the recorded checks.
- Enrollment joins to student, course-offering and result dimensions each preserved **32,593 rows**, with **zero unmatched rows**.
- The interaction-to-resource check covered **8,459,320 rows**, with **zero unmatched resources** and **zero missing activity types**.
- **29,228 enrollments** matched interaction records; **3,365** had no matching interaction records. Absence of records was retained as a separate coverage condition.

These checks support structural integrity at the inspected warehouse level. They do not demonstrate that every source value is complete or that raw-to-clean click totals were preserved.

### 3.3 Cleaning and modeling rules

1. **Text and missing markers:** trimming and case normalization standardize categories; markers such as empty strings, `?`, `NULL` and `N/A` are converted to missing values where specified.
2. **Safe conversion and validity checks:** `TRY_CAST` and related rules convert identifiers, relative days, clicks and other numeric fields. Invalid values are handled explicitly rather than treated as valid observations.
3. **Deduplication:** the clean views use `ROW_NUMBER` rules. The interaction view removes rows identical across module, presentation, student, resource, day and click count. ODS then sums retained click values to the daily resource grain.
4. **Enrollment attributes:** age band, previous attempts, studied credits, registration/unregistration days and final outcome remain associated with enrollment. The student dimension contains gender, region, highest education, IMD band and disability.
5. **Relative time:** day 0 is the course start; negative days precede teaching. `DimRelativeDay` supports relative-day and study-week analysis.
6. **Load controls:** the warehouse script includes transaction handling and ODS-to-DW count/click reconciliation checks before commit. These are script controls; a separate saved execution log proving their results was not supplied.

### 3.4 Analytical eligibility

The notebook constructs expected TMA/CMA opportunities from enrollment × assessment within the same course offering. Registration, due dates, withdrawal dates and timing consistency determine eligibility. Assessments due before registration or after prior withdrawal are excluded; withdrawal on the due day is treated as uncertain. Banked records are distinguished from current submissions.

For early engagement, an enrollment must be eligible for the entire days 0–27 window. **27,229 enrollments** met that eligibility condition; **26,754** had interaction records and **475** did not. Engagement statistics use the measured population. These results therefore exclude early withdrawals and must not be generalized to every enrollment.

For the joint analysis, an enrollment must additionally have eligible current assessment requirements due during days 0–27 and sufficiently reliable submission timing. This leaves **21,533 enrollments** in AAA, BBB, CCC, DDD and FFF; EEE and GGG are absent from that comparison.

## 4. Key Analytical Results

### 4.1 Core outcome KPIs

| KPI | Result |
|---|---:|
| Total enrollments | 32,593 |
| Distinct students | 28,785 |
| Modules / presentations | 7 / 22 |
| PASS, excluding distinction | 12,361 (37.93%) |
| DISTINCTION | 3,024 (9.28%) |
| Successful enrollments: PASS + DISTINCTION | 15,385 (47.20%) |
| Withdrawn enrollments | 10,156 (31.16%) |
| Failed enrollments | 7,052 (21.64%) |
| Combined withdrawal and failure | **17,208 (52.80%)** |
| Unknown / missing outcomes | 0 |
| Success among non-withdrawn enrollments | 68.57% |

Success among non-withdrawn enrollments uses a restricted denominator and should not replace the overall 47.20% success rate.

### 4.2 Module support priorities

| Module | Enrollments | Withdrawn | Failed | Combined affected | Combined rate |
|---|---:|---:|---:|---:|---:|
| CCC | 4,434 | 1,975 | 781 | 2,756 | **62.16%** |
| DDD | 6,272 | 2,250 | 1,412 | 3,662 | **58.39%** |
| FFF | 7,762 | 2,403 | 1,711 | 4,114 | **53.00%** |
| BBB | 7,909 | 2,388 | 1,767 | 4,155 | **52.54%** |
| EEE | 2,934 | 722 | 562 | 1,284 | **43.76%** |
| GGG | 2,534 | 292 | 728 | 1,020 | **40.25%** |
| AAA | 748 | 126 | 91 | 217 | **29.01%** |

CCC and DDD are priorities by rate. BBB and FFF require support capacity because of their larger numbers of affected enrollments. GGG needs a specific academic-performance response: its **28.73% failure rate** is the highest, while withdrawal is **11.52%**.

### 4.3 Withdrawal timing

| Timing | Withdrawals | Share of all withdrawals |
|---|---:|---:|
| Before teaching began | 2,676 | 26.35% |
| Days 0–27 | 2,356 | 23.20% |
| Day 28 onward | 5,031 | 49.54% |
| Unknown day | 93 | 0.92% |

Before-start and days 0–27 withdrawals together account for **49.55%** of withdrawals. These are shares of all withdrawals, not rates among students still enrolled at each time. Periods differ in length. The later **49.54%** also supports continuing assistance beyond the first month.

### 4.4 Study load and previous attempts

| Studied-credit band | Enrollments | Withdrawn | Failed | Combined rate |
|---|---:|---:|---:|---:|
| 1–60 | 20,568 | 5,214 | 4,700 | 48.20% |
| 61–120 | 9,769 | 3,785 | 1,938 | 58.58% |
| Above 120 | 2,256 | 1,157 | 414 | **69.64%** |

Withdrawal increased from **25.35%** in the lowest band to **51.29%** above 120 credits. The pattern also appeared within all seven modules. In CCC, withdrawal rose from **37.22%** to **62.84%** between the lowest and highest bands; in DDD, from **28.59%** to **60.08%**. Studied credits describe the student's total study load at enrollment, rather than the credits of this single module alone.

| Previous attempts at the same module | Enrollments | Failure rate | Withdrawal rate | Combined rate |
|---|---:|---:|---:|---:|
| None | 28,421 | 20.16% | 30.56% | 50.72% |
| One or more | 4,172 | 31.66% | 35.26% | **66.92%** |

The combined gap is **16.20 percentage points**. This is an any-versus-none comparison; it does not establish a fixed increase for every additional attempt.

### 4.5 Deprivation, regional context and academic preparation

The combined rate was **64.84%** in IMD 0–10%, the most deprived band, compared with **42.47%** in IMD 90–100%. In North Western Region, **37.9%** of enrollments were in the most deprived 0–20% bands, alongside a **59.81%** combined rate. South Region recorded **5.9%** and **47.61%**, respectively.

These associations do not mean deprivation alone explains regional outcomes. Wales had the highest regional failure rate, **29.72%**. Missing IMD values affected **40.1%** of North Region enrollments and **22.5%** in Ireland, limiting comparisons.

| Highest prior qualification | Enrollments | Combined withdrawal and failure rate |
|---|---:|---:|
| No formal qualifications | 347 | **70.32%** |
| Lower than A Level | 13,158 | 61.15% |
| A Level or equivalent | 14,045 | 47.97% |
| Higher education qualification | 4,730 | 43.83% |
| Postgraduate qualification | 313 | 34.50% |

Results support reviewing preparation and access needs. The no-formal-qualification and postgraduate groups are relatively small, and differences should be considered alongside module mix, workload and previous attempts.

### 4.6 Assessment completion and timing

The expected-assessment dataset contains **286,898 enrollment–assessment opportunities** for TMA/CMA assessments. Of these, **216,368** were eligible under the timing rules: **165,413 current submissions**, **1,741 banked records** and **49,214 opportunities without a submission record**. Excluding the 1,741 banked records leaves **214,627 eligible current requirements**; **49,214 / 214,627 = 22.93%** had no matching submission record. This preserves the stakeholder headline while making its denominator explicit. If banked records were included in the denominator, the share would instead be 22.75%. Record completeness must be checked before interpreting absence as confirmed non-submission.

| Final outcome | Enrollments in completion comparison | Mean completion per enrollment |
|---|---:|---:|
| PASS | 12,351 | 95.52% |
| DISTINCTION | 3,021 | 96.68% |
| FAIL | 7,029 | 43.67% |
| WITHDRAWN | 5,285 | 58.17% |

Completion averages exclude banked requirements and include only enrollments with at least one eligible current requirement. The withdrawn comparison therefore covers fewer than all 10,156 withdrawals. For these students, only assessments due before withdrawal enter the eligible comparison.

Among **165,410 eligible current submissions with usable timing**, **116,388 (70.36%)** were on time or early and **49,022 (29.64%)** were late. Three eligible current submissions lacked usable timing. Median delay among late submissions was **3 days**. The 70.36% is conditional on a timed submission; it is not the share of all expected opportunities submitted on time.

The stakeholder report prioritizes completion gaps in **GGG, EEE and FFF**, and deadline difficulties in **CCC**. Opportunity-level rates and averages of enrollment-level rates must remain separately labeled.

### 4.7 Early and weekly engagement

| Outcome | Full-window eligible enrollments | With interaction records | Median active days, days 0–27 |
|---|---:|---:|---:|
| PASS | 12,258 | 12,256 | 11 |
| DISTINCTION | 3,008 | 3,008 | 14 |
| FAIL | 6,971 | 6,609 | 7 |
| WITHDRAWN | 4,992 | 4,881 | 8 |
| **Total** | **27,229** | **26,754** | — |

Engagement differs substantially across modules. In AAA, median clicks for WITHDRAWN and PASS were similar, at **275** and **279.5**. Activity volume alone is therefore insufficient, and a universal click threshold would overlook module context.

| Week | SUCCESS mean clicks | WITHDRAWN mean clicks | FAIL mean clicks |
|---|---:|---:|---:|
| 3 | 94.53 | 70.42 | 57.22 |
| 4 | 72.29 | 46.38 | 38.40 |

Weekly populations change with eligibility and withdrawal; these lines do not follow an unchanged cohort. Means include zero-activity weeks for otherwise measured enrollments with interaction records. Changes should be interpreted against teaching and assessment schedules.

### 4.8 Engagement and submission together

| Early engagement / submission | Enrollments | Successful | Failed | Withdrawn | Success rate |
|---|---:|---:|---:|---:|---:|
| High / High | 10,567 | 7,328 | 1,646 | 1,593 | **69.35%** |
| High / Low | 241 | 55 | 86 | 100 | **22.82%** |
| Low / High | 8,730 | 4,389 | 2,571 | 1,770 | **50.27%** |
| Low / Low | 1,995 | 216 | 963 | 816 | **10.83%** |
| **Total** | **21,533** | **11,988** | **5,266** | **4,279** | — |

Both indicators use **days 0–27**. High engagement means positive clicks at or above the median within the same course offering among included enrollments. High submission means at least **80%** of eligible current requirements due in the window were submitted by day 27; banked requirements are excluded.

The contrast supports checking task completion alongside activity. It does not show that raising clicks or moving a student between groups will cause a particular improvement. The high-engagement/low-submission group contains only **241 enrollments**, and EEE/GGG are not represented. Thresholds are exploratory and are not validated alert rules.

## 5. Recommendations

The proposals below preserve the problem definition, support actions and priorities in the supplied stakeholder report. They are proposed interventions, not actions already implemented or proven effective.

| Priority / group | Proposed support |
|---|---|
| **CCC and DDD** | Review study requirements and assessment sequencing; contact students early to understand difficulties continuing study. |
| **BBB and FFF** | Allocate advisers and support sessions in proportion to the number of affected enrollments. |
| **GGG** | Explain difficult concepts, provide practical exercises and support assessment preparation. |
| **Before teaching starts** | Explain course requirements and expected study time, and confirm access to the learning platform. |
| **First four weeks and later study** | Contact students who have not started activities or have missed expected submissions. Continue support before major assessments and when sustained declines emerge. |
| **High study loads, especially above 120 credits** | Review workload against available time and commitments; create weekly schedules, spread submission tasks and offer load adjustments where regulations permit. Provide individual advice before high-load enrollment. |
| **Previous module attempts** | Diagnose remaining learning gaps, establish a repeat-study plan with targeted practice and adviser follow-up, and reassess progress after the first assessment. |
| **Access barriers and deprivation** | Check connectivity, devices and access to support; offer downloadable low-data materials, flexible support hours and referrals to available assistance. Assess individual circumstances when allocating help. |
| **Academic preparation** | Offer introductory study skills, academic writing, numeracy and digital skills; diagnose individual needs and provide worked examples, progressive practice and feedback. |
| **Assessment completion** | Provide a clear calendar and reminders; check record completeness before following up missing submissions. Break larger assignments into stages and explain marking criteria. Review completion gaps in GGG, EEE and FFF and deadline difficulties in CCC. |
| **Early engagement** | Identify essential first-week activities and connect them to assessments. Discuss technical, academic and time barriers with students showing low activity, using module-specific expectations. |
| **Weekly engagement** | Monitor sustained changes relative to earlier activity and the module calendar; offer supportive contact, a follow-up plan and revision sessions, then review submissions and activity after support. |

### 5.1 Support by joint engagement/submission group

| Group | Response from the stakeholder report |
|---|---|
| High engagement / Low submission | Clarify assessment requirements, support time management and help complete the task. |
| Low engagement / High submission | Review grades, learning quality and study methods before deciding on an intervention. |
| Low engagement / Low submission | Prioritize individual contact to explore technical, academic and personal barriers. |
| High engagement / High submission | Continue routine monitoring and offer suitable enrichment activities. |

### 5.2 Evaluate support before expansion

Pilot actions on a limited scale and track **assessment completion, retention and success**. Before expanding, assess changes in combined withdrawal and failure using comparable groups within the same module and presentation. A descriptive baseline does not establish the effect of an intervention.

## 6. Reporting Structure

The following is a **recommended Power BI reporting structure**, derived from the completed analysis. No Power BI file or dashboard export was supplied for verification.

| Page | Purpose | Recommended content |
|---|---|---|
| 1. Executive Overview | Present the scale of the problem | Enrollment and distinct-student cards; success, withdrawal, failure and combined rates; module rate-and-count comparisons |
| 2. Outcomes & Support Needs | Compare groups requiring different assistance | Module/presentation, studied credits, previous attempts, education, IMD and region; counts alongside percentages |
| 3. Withdrawal Timing | Inform pre-start, early and ongoing support | Timing groups, unknown dates and explicitly labeled withdrawal denominators |
| 4. Assessment Completion | Monitor completion and timing | Eligible opportunities; current, banked and missing records; enrollment completion averages; on-time/late rates with denominator labels |
| 5. Early & Weekly Engagement | Assess engagement in course context | Clicks and active days; eligible/measured/unmeasured counts; module-specific and weekly views |
| 6. Engagement × Submission | Connect activity with task completion | Four-group matrix for days 0–27, sample coverage, exploratory thresholds and proposed support |

Recommended slicers include module, presentation, education, study-load band, previous-attempt status, region and IMD band. Apply slicers only where the relevant enrollment attributes and cohort definitions are supported.

Use one-to-many dimension-to-fact relationships and calculate enrollment outcomes from `FactEnrollment`. Aggregate assessment and interaction facts to enrollment grain before combining behavioral summaries. Direct joins between detailed facts can multiply rows, clicks and submission counts. Resource or assessment filtering must not silently redefine the overall enrollment denominator.

## 7. Known Limitations

- **Historical descriptive evidence:** the dataset covers 2013–2014. Results describe associations in these enrollments and do not establish causality, current institutional performance or intervention effectiveness.
- **Different populations:** whole-dataset KPIs, assessment comparisons, full-window engagement and the joint analysis use different eligibility rules. Report the population and denominator beside each measure.
- **Early-window selection:** full-window comparisons exclude early withdrawals. The joint analysis is useful for support after the observation window; it cannot retrospectively identify students who left before completing it.
- **Missing records:** no interaction record is not automatically zero engagement. A missing submission record requires checking completeness before treating it as a confirmed missed task. Missing scores remain missing.
- **Timing uncertainty:** 45 enrollments have missing registration days and 93 withdrawals have unknown withdrawal days. Assessment eligibility handles uncertain or inconsistent timing separately.
- **Completion is not an exam pass rate:** the expected-opportunity analysis covers TMA/CMA requirements. Completion, timeliness, recorded scores and final course outcomes are distinct measures.
- **Changing weekly samples:** weekly trends use changing eligible populations rather than a fixed cohort and should be interpreted with measured counts and course schedules.
- **Segment size and confounding:** small groups can have unstable rates. Module mix, workload, previous attempts, preparation and deprivation may overlap; descriptive comparisons do not isolate their independent effects.
- **Student attributes:** the implemented student dimension stores one profile per student. ODS includes profile-consistency diagnostic queries, but their execution results were not supplied as a separate audit. Changes in those attributes across enrollments would require a revised model; age band is already retained on the enrollment fact.
- **Source-to-warehouse interaction reconciliation:** the saved warehouse contains 8,459,320 interaction rows. Exact-row deduplication precedes daily aggregation. Without raw-to-clean reconciliation outputs, the reduction cannot be attributed entirely to aggregation, and preservation of original raw click totals cannot be claimed.
- **Predictive leakage:** final outcome keys on behavioral facts support retrospective segmentation. Final outcomes and post-window information must not be used as inputs to a prospective early-support model.
- **Execution scope:** this report reviews supplied code and saved outputs; it does not represent a fresh SQL Server execution. Some notebook package-install cells contain pip error messages, although the saved analytical outputs are available. A clean environment run would be needed to establish end-to-end reproducibility.

## 8. Final Validation Checklist

| Validation | Recorded result / status |
|---|---|
| Enrollment count | 32,593 |
| Distinct students | 28,785 |
| Outcome reconciliation | 12,361 PASS + 3,024 DISTINCTION + 7,052 FAIL + 10,156 WITHDRAWN = 32,593 |
| Combined problem indicator | 7,052 FAIL + 10,156 WITHDRAWN = 17,208; 52.80% |
| Key integrity | All 14 inspected combinations passed |
| Declared foreign-key integrity | All 12 checked relationships passed; zero null-key and orphan rows |
| Enrollment dimension joins | 32,593 rows retained; zero unmatched rows for each of three joins |
| Assessment fact / interaction fact | 173,912 / 8,459,320 rows |
| Full-window engagement coverage | 27,229 eligible = 26,754 measured + 475 without interaction records |
| Joint-analysis coverage | 10,567 + 241 + 8,730 + 1,995 = 21,533; five modules |
| Eligible assessment opportunities | 165,413 current + 1,741 banked + 49,214 no record = 216,368 |
| Missing-record headline denominator | 165,413 current + 49,214 no record = 214,627, excluding banked; 22.93% |
| Submission timing | 116,388 on time/early + 49,022 late = 165,410 usable; three unavailable |
| Raw-to-clean interaction/click reconciliation | Not evidenced by a supplied saved reconciliation result |
| Power BI implementation and visual validation | Not verified; reporting structure is proposed |
| Stakeholder alignment | Business problem and support proposals retained from the supplied illustrated report |

---

## Final Management Conclusion

**Withdrawal and academic failure affected 52.80% of OULAD enrollments**, with substantial differences in the type and scale of support needed. CCC and DDD are priorities by combined rate, BBB and FFF by case volume, and GGG by academic failure. High study loads, previous attempts, preparation and access barriers identify additional areas for targeted assistance.

Management should combine preparation before teaching, intensive support in the first four weeks and continuing follow-up throughout the course. Assessment completion and engagement should be reviewed together, using module context and explicit eligibility rules. The proposed actions should be piloted and evaluated against completion, retention and success before expansion.

## Evidence and Source Notes

1. **Stakeholder reference:** `OULAD_Stakeholder_Report_Illustrated_EN(1).docx` — authoritative problem framing and proposed support actions. All ten analytical themes and the final action priorities are retained in this report.
2. **Numerical reference:** `Final_OULAD_Analysis(6).ipynb` — saved warehouse profiles, key/relationship checks, merge checks, KPIs and analytical results. Selected evidence appears in code cells 6, 8, 10, 15, 19, 20, 34, 42, 48, 53, 60, 89, 92, 96, 110, 120, 125, 140, 147, 161 and 163 (zero-based notebook cell positions).
3. **Implementation reference:** the four supplied staging, cleaning, normalization and denormalization SQL scripts, supplemented by the two ERD text files.
4. **Version note:** the stakeholder report cites an earlier filename, `Final_OULAD_Analysis_EN(1).ipynb`. This final report uses the currently supplied `Final_OULAD_Analysis(6).ipynb` for saved-output verification. Reviewed headline and comparison values agree with the stakeholder report.
5. **Format reference:** `HR_Analytics_final_report_and_executive_summary.md` — structure adapted to the OULAD evidence, three-fact model and education-support problem.
