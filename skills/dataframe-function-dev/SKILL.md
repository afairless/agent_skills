---
name: dataframe-function-dev
description: Guidelines for writing and testing functions that take dataframes as input. Covers input validation (column names, data types, row counts, error messages), test structure (schema checks, simple cases, edge cases, combinations, property-based tests), and performance patterns (vectorized code, group-level parallelism). Use when implementing or reviewing any function that processes tabular data, regardless of language (Python, Rust, R) or dataframe library (polars, pandas, arrow, data.table, etc.).
---

# Writing and Testing Dataframe Functions

These guidelines apply to any language (Python, Rust, R, Julia, …) and any
dataframe library (polars, pandas, arrow, data.table, …).  The examples use
Python/polars for concreteness but every principle translates directly.

---

## 1 — Input Validation

Validate inputs at function entry — before any processing — and report any
violation clearly before continuing.  The goal is to detect problems at the
boundary and communicate exactly what needs to be fixed.

How violations are reported — raising an exception, writing to a log, sending
an alert, returning an error value — depends on the deployment context and
should be decided at the project level, not here.  The examples below raise
exceptions because that is concise to write; substitute your project's
reporting mechanism throughout.

### 1.1 Column names

Check that every required column is present.  Name the missing columns in the
message; do not make the caller guess.

```python
# Python / polars
required = {'group', 'start_date', 'end_date'}
missing = required - set(df.columns)
if missing:
    raise ValueError(f"Missing required columns: {sorted(missing)}")
```

```r
# R / data.table
required <- c("group", "start_date", "end_date")
missing  <- setdiff(required, names(df))
if (length(missing) > 0)
    stop(paste("Missing required columns:", paste(missing, collapse = ", ")))
```

### 1.2 Column data types

A type mismatch on a date column or a numeric column produces silent wrong
answers or confusing late-stage errors.  Check each required column's type
immediately and name the offending column.

```python
# polars: check the whole schema at once
expected = pl.Schema({'group': pl.String, 'start_date': pl.Date, 'end_date': pl.Date})
assert df.schema == expected, f"Expected schema {expected}, got {df.schema}"
```

```python
# or check columns individually for finer messages
if df['start_date'].dtype != pl.Date:
    raise TypeError(f"start_date must be Date, got {df['start_date'].dtype}")
```

### 1.3 Minimum row count

If the algorithm requires at least N rows, check for it explicitly.  A function
that silently returns an empty result when called with zero rows is harder to
diagnose than one that detects and reports the violation at the boundary.

```python
if len(df) == 0:
    raise ValueError("Input dataframe must have at least one row")
```

### 1.4 Null / missing values

Nulls in required columns are often just as problematic as a wrong type — they
propagate silently through calculations or cause confusing failures deep inside
the function body.  Decide whether null values are acceptable in each required
column and check for them at the boundary.

```python
# polars
for col in ('start_date', 'end_date'):
    n = df[col].null_count()
    if n > 0:
        raise ValueError(f"{col} contains {n} null value(s)")
```

```r
# R
for (col in c("start_date", "end_date")) {
    n <- sum(is.na(df[[col]]))
    if (n > 0) stop(paste(col, "contains", n, "NA value(s)"))
}
```

If nulls are permitted in a column (e.g., an optional annotation field),
document what the function does with them rather than leaving it implicit.

### 1.5 Value-level constraints

Some preconditions cannot be expressed as column types or row counts — they are
semantic constraints on the *values* themselves.  Common examples:

- `start_date <= end_date` for every row in an interval table
- A numeric column whose values must be within a valid range (e.g., [0, 1])
- No duplicate keys within a group
- A categorical column whose values must come from a known set

Check these explicitly before processing.  When reporting a violation, identify
the offending rows rather than just stating a count.

```python
# polars: find rows where start_date is after end_date
invalid = df.filter(pl.col('start_date') > pl.col('end_date'))
if len(invalid) > 0:
    raise ValueError(
        f"{len(invalid)} row(s) have start_date after end_date:\n{invalid}")
```

A schema validation library (section 1.7) can often express value-level
constraints alongside type constraints, keeping all preconditions in one place.

### 1.6 Error message quality

A good error message states three things:

| What went wrong | What was expected | What was found |
|---|---|---|
| `start_date has wrong type` | `Date` | `Utf8 / String` |
| `Missing required columns` | `{'end_date'}` | *(absent)* |
| `Too few rows` | `>= 1` | `0` |

**Bad:**

```python
assert df.schema == expected_schema
```

**Good:**

```python
assert df.schema == expected_schema, (
    f"Expected schema {expected_schema}, got {df.schema}")
```

### 1.7 Schema validation libraries

Rather than writing checks manually inside each function, specialized libraries
let you declare the valid schema once — as a class or schema object, outside
the function — and attach it to the function automatically.  The library
performs the checks and reports violations according to its own configuration.

| Library | Language / ecosystem |
|---|---|
| `pandera` | Python (pandas, polars, pyspark) |
| `great_expectations` | Python |
| `assertr` | R |
| `validate` | R |

```python
# pandera example (Python / pandas)
import pandera as pa

# Schema declared once, outside any function.
interval_schema = pa.DataFrameSchema({
    "group":     pa.Column(str),
    "start_date": pa.Column(pa.DateTime),
    "end_date":   pa.Column(pa.DateTime),
})

# @pa.check_input runs the schema against the argument before the
# function body executes — no manual checks needed inside.
@pa.check_input(interval_schema)
def merge_intervals(df):
    ...
```

Key advantages of this approach:

- Validation logic stays out of function bodies (separation of concerns).
- A single schema object can be reused across multiple functions that share
  the same contract.
- The schema serves as live documentation of what the function expects.
- How violations are reported is controlled by library configuration, not
  scattered across function bodies.

The tradeoff is a library dependency and learning curve; hand-written checks
(sections 1.1–1.6) may be preferable when the project is small or when the
constraint cannot be expressed in the library's schema language.

When a schema validation library is in use, Layer 1 tests (section 2) still
apply — they now verify that the schema definition itself rejects the inputs it
should reject, rather than testing code inside the function body.

### 1.8 Mutation and copy semantics

Decide whether your function returns a new dataframe or modifies the input in
place, and apply that contract consistently.

Most functional-style dataframe code returns a new dataframe and leaves the
input unchanged.  Some libraries make this the default (polars DataFrames are
immutable); others leave it ambiguous (pandas operations may copy or modify
depending on context and version).  Document the contract explicitly, and test
it:

```python
def test_input_not_mutated():
    original = input_df.clone()   # polars; use .copy() for pandas
    merge_intervals(input_df)
    assert_frame_equal(input_df, original)
```

In-place mutation is occasionally appropriate for performance reasons, but must
be clearly documented and consistently applied.  Never silently mutate a
caller's dataframe if the contract does not promise it.

---

## 2 — Test Structure

Build the test suite in layers, from simplest to most complex.  Each layer
catches a different class of problem; do not skip layers on the assumption that
harder tests cover the simpler ones.

### Layer 1 — Schema / input-validation tests

One test per validation check.  Each test passes a DataFrame that violates
exactly one constraint and verifies that the violation is detected and reported.
The assertion depends on how your project reports violations: check for a raised
exception, an expected log entry, a returned error value, etc.

| Constraint | What to pass |
|---|---|
| Required columns present | `{}` (no columns), or rename one required column |
| Each column's data type | pass `start_date` as a string instead of Date |
| Minimum row count | zero-row DataFrame with the correct columns |

These tests document the contract of the function and catch regressions when
validation logic is refactored.

```python
# Examples assume violations are reported by raising an exception.
# Replace pytest.raises(...) with the assertion appropriate for your
# reporting mechanism (log assertion, return-value check, etc.).

def test_empty_dataframe():
    with pytest.raises((ValueError, AssertionError)):
        merge_intervals(pl.DataFrame({}))

def test_wrong_column_name():
    df = pl.DataFrame({'category': ['aa'], 'start_date': [date(2020,1,1)],
                       'end_date': [date(2020,6,1)]})
    with pytest.raises((ValueError, AssertionError)):
        merge_intervals(df)

def test_wrong_type_on_start_date():
    df = pl.DataFrame({'group': ['aa'], 'start_date': ['2020-01-01'],
                       'end_date': [date(2020,6,1)]})
    with pytest.raises((ValueError, AssertionError, TypeError)):
        merge_intervals(df)
```

### Layer 2 — Minimal valid input

Test the smallest input that exercises the core logic.  These cases are fast to
read and fast to diagnose.

- **Single row** — output equals input; nothing is merged, nothing is dropped.
- **Two rows, no merge** — output equals input; function must leave them alone.
- **Two rows, merge required** — verify the merged output exactly.

```python
def test_single_row():
    df = make_df([('aa', '2020-01-01', '2020-06-01')])
    assert_frame_equal(merge_intervals(df), df)
```

### Layer 3 — Core behavior cases

Enumerate the logically distinct cases your function must handle.  For merging
overlapping date intervals, the exhaustive set of two-interval relationships is:

| Case | Relationship | Merged? |
|---|---|---|
| Overlap | end of first > start of second | Yes |
| Touching | end of first == start of second | Yes |
| Contiguous / adjacent | end of first is one day before start of second | Yes |
| Gap (non-adjacent) | end of first ≥ 2 days before start of second | No |
| Containment | one interval fully inside the other | Yes |
| Exact duplicate | identical intervals | Yes (deduplicated) |

Test each case with a small, hand-verified example.  The expected output should
be written out explicitly, not computed by calling the function again.

### Layer 4 — Compound and realistic inputs

- **Multiple categories** — each category has its own merge; verify they do not
  bleed into each other.
- **Scrambled / unsorted input** — never assume the caller has sorted the data.
  Pass rows in random order and verify the output is still correct.
- **Transitive merges** — A overlaps B, B overlaps C, but A does not directly
  overlap C.  All three must merge into one.

```python
def test_transitive_overlap():
    # [Jan–Apr], [Mar–Jul], [Jun–Sep] → [Jan–Sep]
    df = make_df([('aa','2020-01-01','2020-04-01'),
                  ('aa','2020-03-01','2020-07-01'),
                  ('aa','2020-06-01','2020-09-01')])
    expected = make_df([('aa','2020-01-01','2020-09-01')])
    assert_frame_equal(merge_intervals(df), expected)
```

### Layer 5 — Property-based tests

Use property-based (generative) tests when exhaustive enumeration of cases is
infeasible.  Define invariants that must hold for any valid input and let the
framework generate thousands of random examples.

Useful properties for dataframe functions:

| Property | Description |
|---|---|
| **Idempotency** | `f(f(df)) == f(df)` — running twice gives the same result |
| **Row count monotonicity** | output rows ≤ input rows (for merge/aggregate functions) |
| **Coverage preservation** | union of output intervals == union of input intervals |
| **Schema preservation** | output has the same column names and types as input |
| **Determinism** | same input always produces the same output |
| **Permutation invariance** | shuffling input rows does not change output |

Libraries: `hypothesis` (Python), `proptest` / `quickcheck` (Rust),
`hedgehog` / `quickcheck` (R / Haskell).

```python
from hypothesis import given, settings
import hypothesis.strategies as st

@given(st.lists(st.dates(), min_size=1))
def test_idempotent(dates):
    df = build_random_intervals(dates)
    once  = merge_intervals(df)
    twice = merge_intervals(once)
    assert_frame_equal(once, twice)
```

---

## 3 — Performance

### 3.1 Vectorized operations

Avoid row-by-row iteration when the library provides a vectorized equivalent.
Vectorized operations execute in compiled code and are often 10–1000× faster.

```python
# Slow: Python loop
result = [row['value'] * 2 for row in df.iter_rows(named=True)]

# Fast: vectorized expression
df = df.with_columns(pl.col('value') * 2)
```

Some algorithms are inherently sequential (e.g., a sweep-line merge that
carries state from one interval to the next).  For those, pull the columns into
plain lists before the loop rather than accessing DataFrame rows inside it —
this avoids per-row overhead from the dataframe layer.

```python
# Extract once, loop over plain Python lists
starts = df['start_date'].to_list()
ends   = df['end_date'].to_list()
# ... loop over starts and ends ...
```

### 3.2 Built-in group-level parallelism

Many dataframe libraries automatically parallelize `group_by` + aggregate or
`group_by` + map operations.  When your function processes each category
independently, structure the code to use this API so the library can schedule
work across CPU cores without any extra effort.

| Library | Parallel group-level API |
|---|---|
| polars (Python / Rust) | `group_by(...).map_groups(fn)` |
| pandas | `groupby(...).apply(fn)` + `swifter` / `pandarallel` for threads |
| R data.table | `DT[, fn(.SD), by = group]` (OpenMP threads) |
| R dplyr + multidplyr | `group_by(...) \|> partition(cluster) \|> summarise(...)` |
| Rust polars | same `group_by().apply()` — compiled, automatically threaded |

### 3.3 Benchmark before optimizing

Write correct, readable code first.  Profile with realistic data sizes before
rewriting.  Premature micro-optimizations inside a function that runs in 2 ms
are wasted effort.

---

## 4 — Checklist

Before marking a dataframe function complete:

**Input validation**

- [ ] Checks that all required column names are present; names the missing columns in the message
- [ ] Checks the data type of each required column; names the offending column and states the expected type
- [ ] Checks minimum row count if the algorithm requires it
- [ ] Checks required columns for nulls; documents what the function does if nulls are permitted
- [ ] Checks value-level constraints (e.g., `start_date <= end_date`) that cannot be expressed by schema alone; identifies the offending rows
- [ ] Every violation message states what was expected and what was found
- [ ] Documents and tests whether the function mutates the input or returns a new dataframe

**Test coverage**

- [ ] One test per validation check (Layer 1)
- [ ] Single-row and minimal two-row cases (Layer 2)
- [ ] Every logically distinct case for the core behavior, with explicit expected outputs (Layer 3)
- [ ] Scrambled/unsorted input and multi-category input (Layer 4)
- [ ] Property-based tests for idempotency, permutation invariance, or coverage preservation where exhaustive enumeration is infeasible (Layer 5)

**Performance**

- [ ] Hot paths use vectorized operations; no row-by-row loops in the dataframe layer
- [ ] Per-category work uses the library's parallel `group_by` API where available
- [ ] Sequential algorithms pull data into plain lists/arrays before looping

---

## 5 — Related Skills

- **[data-contracts](../data-contracts/SKILL.md)** — Data quality contracts at every boundary: validation, type conversion, null handling, and schema evolution. Every dataframe function is a transformation-stage component; its input and output contracts should be explicit.
- **[data-pipeline-architecture](../data-pipeline-architecture/SKILL.md)** — The three-stage model (ingestion → transformation → output). Understand where your dataframe function fits in the pipeline.
- **[data-pipeline-reliability](../data-pipeline-reliability/SKILL.md)** — Production reliability: idempotency, monitoring, and performance patterns relevant to dataframe pipelines.
- **[testing-guide](../testing-guide/SKILL.md)** — General testing methodology, including the None-One-Many parameter principle.
