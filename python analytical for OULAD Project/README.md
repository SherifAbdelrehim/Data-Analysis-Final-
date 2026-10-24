# OULAD Student Performance Analysis

An exploratory analysis of how learning-platform engagement, assessment submission, study load and student characteristics relate to success, failure and withdrawal in the Open University Learning Analytics Dataset (OULAD).

The notebook reads a prepared SQL Server database directly. Its findings describe historical associations and do not establish causality or constitute a validated early-warning model.

## Files to share

| File | Purpose |
|---|---|
| `Final_OULAD_Analysis_EN(1).ipynb` | Current English analysis notebook |
| `requirements.txt` | Python packages and versions exported from the author's project environment |
| `README.md` | Setup and execution instructions |
| Database backup or approved connection details | Access to the prepared database required to rerun the analysis |

Optional supporting documents include the executive summary and the separate chart interpretation report.

The notebook may be renamed when shared. If its filename differs, open the corresponding `.ipynb` file. Do not send the `.venv_OULAD` folder; each recipient should create a local environment.

## Prerequisites

The setup below targets Windows and VS Code, matching the notebook's Windows Authentication connection.

- **Python 3.12:** the supplied notebook metadata records **Python 3.12.9**. Use the same Python version where practical to reduce compatibility differences.
- **VS Code**, with the Microsoft **Python** and **Jupyter** extensions, or an equivalent Jupyter environment.
- **Microsoft ODBC Driver 18 for SQL Server**, installed separately from Python packages.
- Access to a running **SQL Server** instance containing the prepared OULAD database.
- Permission to read the required tables and inspect their keys and relationships.
- The `requirements.txt` exported from the project environment.

Installing `pyodbc` with pip does **not** install the Microsoft ODBC driver. The requirements file also does not include the database, Python itself or VS Code extensions.

## 1. Create the Python environment

Place the notebook, `requirements.txt` and this README in the same project folder. Open that folder in VS Code and open a terminal there.

Create an environment using your installed Python 3.12 interpreter:

```powershell
py -3.12 -m venv .venv_OULAD
```

Install the shared dependencies:

```powershell
.\.venv_OULAD\Scripts\python.exe -m pip install -r requirements.txt
.\.venv_OULAD\Scripts\python.exe -m pip check
```

These commands use the environment's interpreter directly; activation is not required. If `py -3.12` is unavailable, install Python 3.12 or use the full path to the intended Python executable when creating the environment.

The notebook uses pandas, NumPy, Matplotlib, seaborn, SQLAlchemy, pyodbc, IPython, ipywidgets and Jinja2. Use the supplied requirements file for package versions rather than assuming that the latest releases reproduce the author's environment.

### Select the notebook kernel

1. Open `Final_OULAD_Analysis_EN(1).ipynb` in VS Code.
2. Click **Select Kernel** in the notebook toolbar.
3. Select the Python interpreter inside `.venv_OULAD`.
4. If VS Code requests `ipykernel`, allow installation into this environment, or run:

```powershell
.\.venv_OULAD\Scripts\python.exe -m pip install ipykernel
```

Verify the selected interpreter in a notebook cell:

```python
import sys
print(sys.executable)
print(sys.version)
```

The executable path should point to the project environment. Selecting a Python interpreter for the editor does not replace checking the notebook's selected kernel.

## 2. Prepare database access

Choose one of these approaches:

- **Local database:** obtain the project database backup from the author, restore it to a compatible SQL Server instance, and use the restored database name.
- **Shared server:** obtain the server address, database name and approved access from the database owner.

The notebook expects the prepared warehouse, not just the original OULAD CSV files. Installing packages does not create, populate or restore the database.

### Required tables

| Schema | Tables |
|---|---|
| `dw` | `FactEnrollment`, `FactStudentAssessment`, `FactDailyInteraction` |
| `dw` | `DimStudent`, `DimCourseOffering`, `DimFinalResult`, `DimRelativeDay`, `DimAssessment`, `DimLearningResource` |
| `ods` | `Assessment` |

**The ODS table is required.** Assessment analysis reads `ods.Assessment` to map `AssessmentID` to `CourseOfferingCode`, because that mapping is not available in `dw.DimAssessment`.

Use the project schema and column definitions. Recreating only the table names is insufficient. Preserve primary keys, unique keys and foreign keys because the notebook inspects and validates them.

## 3. Configure the SQL Server connection

In the notebook's connection cell, replace the author-specific server name with your server or instance name, and confirm the database name:

```python
server_name = r"YOUR_SERVER\YOUR_INSTANCE"
database_name = "OULAD"
```

For a default instance, use its server name without an instance suffix.

The existing connection uses:

```text
DRIVER={ODBC Driver 18 for SQL Server};
Trusted_Connection=yes;
TrustServerCertificate=yes;
```

`Trusted_Connection=yes` uses the Windows identity running Python. That account must have database access. If your organization requires another authentication method or certificate configuration, obtain the appropriate connection settings from the database administrator.

Confirm that the driver is available from the selected notebook kernel:

```python
import pyodbc
print(pyodbc.drivers())
```

The list should include `ODBC Driver 18 for SQL Server`.

Run the existing connection test. It prints the connected server and database using `@@SERVERNAME` and `DB_NAME()`. Confirm that they identify the intended data source before continuing.

## 4. Run the notebook

1. Confirm the project kernel and database connection.
2. Restart the kernel to begin with a clean session.
3. Execute cells from top to bottom. Later sections depend on earlier DataFrames and calculated columns.
4. Review key, relationship and merge checks before interpreting charts. Resolve failed checks rather than skipping assertions.
5. Use interactive filters after the relevant widget cells have run.

The notebook contains `%pip install` cells for Jinja2 and ipywidgets. Install the shared requirements first. Those cells may still need internet access if a required package is missing.

**Memory use:** the initial loading cell discovers and loads every table in the `dw` schema into pandas, including the large `FactDailyInteraction` table. Later SQL queries aggregate engagement data, but do not remove the memory cost of that initial load. Allow sufficient RAM and execution time; avoid adding unrelated tables to `dw` for this workflow. Any change to the loading strategy must retain the DataFrames used later in the notebook.

Saved outputs can be viewed without reconnecting, but regenerating tables, charts and interactive controls requires the runtime and database. Displayed outputs may belong to an earlier execution until the notebook is rerun.

## Analysis sections

- Database connection, table loading and integrity checks.
- Overall outcomes and comparisons by student characteristics, module and presentation.
- Withdrawal timing, study load, previous attempts, year and presentation term.
- Assessment eligibility, current and banked submissions, completion, timing and scores.
- Early engagement, weekly activity and learning-resource use.
- Joint comparison of early engagement and assessment submission.

## Interpretation notes

- An **enrollment** is a student registered in one course offering; a student can have multiple enrollments.
- **Success** combines `PASS` and `DISTINCTION`; distinction is not an additional outcome to add to success.
- Timing and engagement comparisons use their stated eligibility rules and denominators. First-four-week results do not describe every enrollment.
- Missing interaction or submission records must not automatically be interpreted as confirmed inactivity or non-submission.
- A day value is relative to the course start. Negative values may represent activity or registration before day 0.
- Final outcomes are retrospective. Future support alerts must use only information available when the alert would be issued.

## Troubleshooting

| Issue | What to check |
|---|---|
| `ModuleNotFoundError` | Confirm the notebook kernel, then install requirements using that environment's Python executable. |
| ODBC driver or DSN error | Confirm ODBC Driver 18 is installed and its name matches the connection string. |
| Login failed or database unavailable | Verify the server, database, network access and permissions of the current Windows account. |
| Invalid object name such as `ods.Assessment` | Confirm that both the required `dw` and `ods` objects exist in the selected database. |
| `NameError` for a DataFrame or derived column | Restart and run preceding cells in order. |
| Widget does not display | Confirm ipywidgets is installed in the selected kernel and rerun the widget cell. |
| Kernel stops or memory error | Review the full-table loading cell and available memory, particularly for daily interaction data. |
| Key, foreign-key or merge assertion fails | Inspect the reported records and verify the database version and schema. |

## Updating dependencies before sharing

The author should export dependencies from the environment that actually runs the notebook:

```powershell
.\.venv_OULAD\Scripts\python.exe -m pip freeze > requirements.txt
```

`pip freeze` records installed packages and versions, including packages that the notebook may not use. It does not record the Python version, system drivers or database state. Keep this README and the requirements file aligned with the environment used for the shared notebook.

## Official setup references

- [Python virtual environments and requirements files](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/)
- [Jupyter notebooks in VS Code](https://code.visualstudio.com/docs/datascience/jupyter-notebooks)
- [Microsoft ODBC Driver for SQL Server](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server)
- [pip freeze documentation](https://pip.pypa.io/en/stable/cli/pip_freeze/)
