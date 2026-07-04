---
name: data-pipeline-reliability
description: Operational principles for running data pipelines safely in production. Covers idempotency, replayability, audit trails, monitoring/observability, and performance proportionality. Use when deploying, maintaining, or hardening any data processing pipeline.
---

# Data Pipeline Reliability

## Why This Skill Exists

Data pipelines that work correctly on the first run often fail in production
for reasons that have nothing to do with the core logic: partial failures
during retries, duplicate outputs from replayed jobs, silent data loss from
unmonitored stages, and performance degradation under real workloads.

**This skill mandates reliability practices for data pipelines running in
production.** Apply it whenever a pipeline graduates from development to an
environment where correctness, recoverability, and observability matter.

For the architectural model that divides data flow into stages, see
**[data-pipeline-architecture](../data-pipeline-architecture/SKILL.md)**.
For contracts that enforce data quality at each boundary, see
**[data-contracts](../data-contracts/SKILL.md)**.

---

## Idempotency

### What It Is

An idempotent pipeline produces the same result no matter how many times it
runs with the same input. This is the single most important property for
production reliability — without it, every retry, replay, or duplicate
delivery risks corrupting downstream data.

### Idempotent Output Writing

The output stage must be designed so that writing the same result set twice is
harmless. Common strategies:

| Strategy | How it works | When to use |
|---|---|---|
| **Partition overwrite** | Write to a dated partition; overwrite on re-run | Daily/hourly batch jobs |
| **UPSERT / MERGE** | Insert if not exists, update if exists, keyed on a natural key | Relational databases, data warehouses |
| **Transactional writes** | Write in a transaction; roll back on failure | ACID databases |
| **Append-only with deduplication** | Append new records; deduplicate on read | Event streams, immutable logs |
| **Write-then-swap** | Write to a temp location, atomically swap on success | File outputs, object stores |

```python
# ✅ Idempotent output: overwrite partition for the run date
def write_partition(records: list[OutputRecord], run_date: date) -> None:
    partition_path = f"s3://bucket/output/dt={run_date.isoformat()}/"
    # Overwrite the partition — safe because re-run produces same data
    write_parquet(records, partition_path, mode="overwrite")
```

```python
# ❌ Not idempotent: append without deduplication
def write_records(records: list[OutputRecord]) -> None:
    write_parquet(records, output_path, mode="append")
    # A retry appends the same records again — duplicates!
```

```python
# ✅ Idempotent: UPSERT with a natural key
def upsert_to_db(records: list[OutputRecord], conn: Connection) -> None:
    for r in records:
        conn.execute("""
            INSERT INTO orders (id, customer_id, total)
            VALUES (?, ?, ?)
            ON CONFLICT (id) DO UPDATE
            SET customer_id = excluded.customer_id,
                total = excluded.total
        """, (r.id, r.customer_id, r.total))
```

### Deterministic Transformation

Beyond the output stage, the transformation logic itself should be
deterministic. Common sources of non-determinism:

| Source | How to eliminate |
|---|---|
| `datetime.now()` | Pass the run timestamp as a parameter, not a side effect |
| `random()` | Use a seeded PRNG with the run date as seed |
| `set()` / `dict` iteration order | Sort before iterating if order matters |
| `ORDER BY` without deterministic tiebreaker | Add a unique tiebreaker column |
| External API calls | Cache responses keyed by request; use the cache on replay |

```python
# ✅ Deterministic: timestamp passed explicitly
def transform(records: list[RawRecord], run_time: datetime) -> list[TransformedRecord]:
    return [TransformedRecord(..., processed_at=run_time) for r in records]

# ❌ Non-deterministic: timestamp from side effect
def transform(records: list[RawRecord]) -> list[TransformedRecord]:
    return [TransformedRecord(..., processed_at=datetime.now()) for r in records]
```

---

## Replayability

Idempotency makes replayability *safe*. Replayability is the ability to re-run
the pipeline (or a subset of stages) from a known starting point.

### Design for Partial Replay

If a bug is discovered in the *output formatting* stage, you should not need
to re-run ingestion and transformation. Architect the pipeline so each stage
writes its results to intermediate storage:

```
Ingestion ──▶ storage/raw/ ──▶ Transformation ──▶ storage/intermediate/ ──▶ Output
           ▲                                  ▲
           │      Replay from this point      │
           │      when schema changes         │    Replay from this point
           │                                  │    when formatting changes
```

```python
def run_pipeline(run_date: date, stages: set[str]) -> None:
    """Run selected stages with replay support."""
    if "ingest" in stages:
        raw = ingest(run_date)
        write_raw(raw, run_date)    # Write to intermediate storage
    if "transform" in stages:
        raw = read_raw(run_date)    # Read from intermediate storage
        transformed = transform(raw, run_date)
        write_intermediate(transformed, run_date)
    if "output" in stages:
        transformed = read_intermediate(run_date)
        output = to_final_format(transformed)
        write_output(output, run_date)
```

### Replay Checklist

Before a production deployment, verify:

- [ ] The pipeline can be re-run from the start with the same input and produce
  identical output.
- [ ] Each stage can be re-run independently using intermediate storage.
- [ ] Intermediate storage is not cleaned up until the full pipeline succeeds.
- [ ] The replay mechanism has been tested — not just designed.

---

## Audit Trail and Data Provenance

Every record that flows through the system should be traceable: where did it
come from, what was done to it, and when?

### What to Track

| Metadata | Purpose |
|---|---|
| **Source** | Where the data originated (file path, API endpoint, database table, Kafka topic) |
| **Ingested at** | Timestamp when the record entered the system |
| **Source version** | Schema version or generation timestamp of the source |
| **Pipeline run ID** | Unique identifier for the processing run |
| **Transformations applied** | Which functions/stages modified the record |
| **Record lineage** | Mapping from output records back to input records (1:1, N:1, 1:N) |

### Implementation

Audit metadata should be attached to records as they flow through the system,
not stored in a separate log that can drift:

```python
@dataclass
class AuditedRecord:
    record: TransformedRecord
    audit: AuditInfo

@dataclass
class AuditInfo:
    source: str                     # "s3://bucket/raw/2024-01-01.csv"
    ingested_at: datetime            # When it entered the system
    run_id: str                      # UUID of this pipeline run
    transformations: list[str]       # ["enrich_with_pricing", "apply_discounts"]
    input_record_ids: list[str]      # Trace back to original input records
```

Do not log sensitive data in audit metadata. PII, secrets, and credentials
belong to the records themselves (if the pipeline needs them) or should be
redacted. See
**[security-guardrails](../security-guardrails/SKILL.md)** for guidance.

---

## Monitoring and Observability

A pipeline running without visible metrics is a pipeline accumulating silent
failure. Every stage should emit observability data.

### Per-Stage Metrics

| Metric | What it tells you |
|---|---|
| **Records in** | Is data arriving? |
| **Records out** | Is processing working? |
| **Records rejected** | Are contracts being violated? (monitor for spikes) |
| **Latency** | How long does this stage take? (watch for drift) |
| **Throughput** | Records per second (capacity planning) |
| **DLQ depth** | How many records are waiting for inspection? |
| **Error rate** | Are transient failures increasing? |

```python
def transform_with_metrics(records: list[RawRecord]) -> list[TransformedRecord]:
    started_at = time.monotonic()
    rejected = 0
    results = []

    for record in records:
        try:
            results.append(transform(record))
        except ContractViolationError:
            rejected += 1
            dead_letter_queue.append(record)

    duration = time.monotonic() - started_at
    METRICS.gauge("pipeline.transform.records_in", len(records))
    METRICS.gauge("pipeline.transform.records_out", len(results))
    METRICS.gauge("pipeline.transform.records_rejected", rejected)
    METRICS.gauge("pipeline.transform.latency_seconds", duration)
    METRICS.gauge("pipeline.transform.throughput_rps",
                   len(records) / duration if duration > 0 else 0)
    METRICS.gauge("pipeline.transform.dlq_depth", dead_letter_queue.size())

    return results
```

### Alerting Thresholds

Metrics are passive without alerts. Define thresholds that signal real problems:

| Alert | Condition | Severity |
|---|---|---|
| No records processed | Records in == 0 for expected batch window | Critical |
| Rejection rate spike | `rejected / total > 0.05` (5% threshold) | Warning |
| Latency drift | P50 latency > 2× baseline for 3 consecutive runs | Warning |
| DLQ growth | DLQ depth increasing run-over-run | Warning |
| Stage failure | Any stage exits with non-zero status | Critical |

---

## Performance Proportionality

The computational cost of each stage should be proportional to the complexity
of the data and the work being done.

### Avoid Re-Parsing and Re-Validating

Data that is unchanged across stages should not be re-validated or re-parsed:

```python
# ❌ Bad: re-validates data that hasn't changed
def transform_to_normalized(priced: list[PricedRecord]) -> list[NormalizedRecord]:
    for r in priced:
        if r.customer_id is None:     # Already validated in ingestion!
            raise ValidationError(...)
        ...

# ✅ Good: trust upstream contracts
def transform_to_normalized(priced: list[PricedRecord]) -> list[NormalizedRecord]:
    # Trust that customer_id is non-null per the ingestion contract
    for r in priced:
        yield NormalizedRecord(customer_id=r.customer_id, ...)
```

### Algorithmic Complexity Awareness

Transformation functions must be designed with data volume in mind:

```python
# ❌ O(n²): nested loop over all records
def find_duplicates(records: list[Record]) -> list[Record]:
    duplicates = []
    for i, a in enumerate(records):
        for j, b in enumerate(records):
            if i != j and a.id == b.id:
                duplicates.append(a)
    return duplicates

# ✅ O(n): use a hash set
def find_duplicates(records: list[Record]) -> list[Record]:
    seen = set()
    duplicates = []
    for r in records:
        if r.id in seen:
            duplicates.append(r)
        seen.add(r.id)
    return duplicates
```

Key principle: **test with realistic data volumes before deploying.** A
function that works with 100 records may fail or time out with 10 million.
See **[dataframe-function-dev](../dataframe-function-dev/SKILL.md)** for
vectorized operation patterns.

---

## Checklist: Production Readiness

Before deploying a pipeline to production:

**Idempotency**

- [ ] Re-running the pipeline with the same input produces identical output
- [ ] The output stage uses an idempotent write strategy (overwrite, UPSERT, transaction)
- [ ] Transformation logic is deterministic (no `datetime.now()`, `random()`, or unordered iteration without explicit sorting)

**Replayability**

- [ ] Each stage writes to intermediate storage before the next stage begins
- [ ] Individual stages can be replayed independently
- [ ] A replay has been tested — not just designed

**Audit**

- [ ] Every output record carries provenance metadata (source, timestamps, run ID, transformations applied)
- [ ] Record lineage can be traced from output back to input
- [ ] Audit metadata does not contain PII or secrets

**Monitoring**

- [ ] Every stage emits records-in, records-out, records-rejected metrics
- [ ] DLQ depth is exposed as a metric
- [ ] Latency and throughput are tracked per stage
- [ ] Alerts are configured for the critical thresholds (see table above)

**Performance**

- [ ] Data is not re-validated or re-parsed across stages unnecessarily
- [ ] Transformation algorithms are O(n) or O(n log n) for expected data volumes
- [ ] The pipeline has been tested with at least 10× the current production volume

---

## Related Skills

- **[data-pipeline-architecture](../data-pipeline-architecture/SKILL.md)** — The three-stage model (ingestion → transformation → output) that pipelines should follow.
- **[data-contracts](../data-contracts/SKILL.md)** — Defining and enforcing data quality contracts at every boundary.
- **[dataframe-function-dev](../dataframe-function-dev/SKILL.md)** — Performance patterns (vectorized operations, parallelism) for transformation-stage functions.
- **[testing-guide](../testing-guide/SKILL.md)** — Property-based testing for idempotency and determinism invariants.
- **[security-guardrails](../security-guardrails/SKILL.md)** — Principles for not logging sensitive data, which applies to audit trails.
