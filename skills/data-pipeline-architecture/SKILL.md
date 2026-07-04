---
name: data-pipeline-architecture
description: Foundational system design principle that data should flow through clearly separated stages — ingestion, transformation, and output — each with distinct responsibilities. Use when designing any system that moves data between components, from ETL pipelines to everyday application modules.
---

# Data Pipeline Architecture

## Why This Skill Exists

Data processing in software systems is often approached without a clear separation
of concerns. Functions and modules mix validation with transformation, change data
formats prematurely, or skip the deliberate step of preparing data for the next
consumer. The result is code that is hard to reason about, hard to test, and
brittle under change.

**This skill mandates a three-stage model for data flow.** Every data processing
pipeline — whether it's a batch ETL job, a microservice request handler, or a
module that reshapes data for a UI — should separate ingestion, transformation,
and output into distinct stages with clear boundaries.

---

## The Three Stages

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│  Ingestion  │────▶│  Transformation  │────▶│   Output    │
│  Stage      │     │  Stage           │     │  Stage      │
└─────────────┘     └──────────────────┘     └─────────────┘
```

### Stage 1: Ingestion

**Purpose:** Receive data from an external source and validate that it is in the
expected form. Do not change it.

Data enters the system here. This is a *boundary* — the transition from the
outside world into the system's domain. The ingestion stage's sole responsibilities
are:

| Do | Don't |
|---|---|
| Validate that required fields are present | Change data types |
| Validate that data types match expectations | Convert between types |
| Validate that values are within expected ranges | Apply business logic |
| Timestamp or log the arrival of the data | Restructure or reshape the data |
| Reject or quarantine malformed data | Fill in missing values or apply defaults |
| Record provenance (source, arrival time) | Join with other datasets |

The principle is simple: **validate and record, don't transform.** A reader of the
ingestion code should see only checks and logging. Any data that passes through
ingestion should be in exactly the same form it arrived in — just verified to be
acceptable.

```python
# ✅ Good ingestion: validate only, do not transform
def ingest(raw_payload: dict) -> RawRecord:
    if "customer_id" not in raw_payload:
        raise ValidationError("Missing required field: customer_id")
    if not isinstance(raw_payload["customer_id"], str):
        raise ValidationError("customer_id must be a string")
    LOGGER.info("Ingested record for customer %s", raw_payload["customer_id"])
    return RawRecord(
        id=raw_payload.get("id"),
        customer_id=raw_payload["customer_id"],
        items=raw_payload.get("items", []),
        ingested_at=datetime.now(timezone.utc),
    )
```

```python
# ❌ Bad ingestion: transforming during validation
def ingest(raw_payload: dict) -> ProcessedOrder:
    # Prematurely converting types and restructuring
    items = [Item.from_dict(i) for i in raw_payload["items"]]
    total = sum(item.price for item in items)
    return ProcessedOrder(...)
```

**Why this separation matters:**

- When a bug is discovered, you can replay ingestion with the same raw data to
  reproduce the issue exactly.
- Raw data is preserved in its original form for downstream audit.
- Ingestion validation can be tested independently of transformation logic.
- Adding a new data source only requires a new ingestion path; the rest of the
  pipeline is unchanged.

### Stage 2: Transformation

**Purpose:** Apply business logic, convert types, enrich data, and produce the
domain model that the system needs.

This is where the *work* happens. Transformation takes the validated, unchanged
data from ingestion and processes it into the form the system's logic requires.
Multiple transformation steps may be chained, but each step must maintain a
**data quality contract** with the next — every possible value a step can produce
must be valid input for whatever comes next.

| Do | Don't |
|---|---|
| Convert between data types | Mix validation into transformation without clear boundaries |
| Validate results of each conversion | Skip type conversion validation |
| Handle null/sentinel values explicitly | Pass nulls downstream without documenting the contract |
| Enforce range limits and domain constraints | Let impossible values leak to later stages |
| Reshape and restructure data | Change the format for convenience of later steps |
| Join, aggregate, and enrich | Leave the data in the ingestion format |

```python
# ✅ Good transformation: validate results, maintain contracts
def enrich_with_pricing(records: list[RawRecord]) -> list[PricedRecord]:
    """Add product prices to raw records. Null prices are explicit."""
    result = []
    for record in records:
        for item in record.items:
            price = price_lookup.get(item.sku)
            if price is None:
                # Contract with next step: price can be None, documented here
                LOGGER.warning("No price found for SKU %s", item.sku)
            result.append(PricedRecord(
                customer_id=record.customer_id,
                sku=item.sku,
                quantity=item.quantity,
                price=price,  # None is a valid value per this function's contract
            ))
    return result

def apply_discounts(records: list[PricedRecord]) -> list[DiscountedRecord]:
    """Apply customer discounts. Requires valid PricedRecord inputs."""
    for record in records:
        if record.price is None:
            # Contract: null prices pass through unchanged
            yield DiscountedRecord(..., price=None)
        else:
            if record.price < 0:
                raise ValueError(
                    f"Contract violation: price {record.price} is negative for SKU {record.sku}")
            discount = get_discount(record.customer_id)
            yield DiscountedRecord(..., price=record.price * (1 - discount))
```

**Data quality contracts between transformation steps:**

Every transformation function or class has an implicit contract with its caller
and its downstream consumer. Make that contract explicit:

- **What values can this function return?** Document the full set of valid outputs.
- **What does this function do with nulls, zeros, empty collections?**
- **What ranges are valid for numeric outputs?**
- **What error conditions can it raise?**

A contract violation anywhere in the chain should be detectable and reportable.
See **[data-contracts](../data-contracts/SKILL.md)** for detailed patterns.

### Stage 3: Output

**Purpose:** Adjust data into the exact format the consumer expects.

This is the final stage — the transition from the system's internal representation
to whatever the next consumer needs. The consumer might be:

- Another software component (an API client, a database, a message queue)
- A human user (a UI, a report, a file download)
- Storage (a data warehouse table, an object store, a log)

This stage exists because the transformation stage often uses formats that are
*efficient for computation* (normalized tables, graph structures, in-memory
representations) but not *convenient for the consumer* (denormalized tables,
JSON, CSV, protobuf messages).

| Do | Don't |
|---|---|
| Convert to the consumer's required format | Apply business logic or transformations |
| Denormalize if the consumer needs it | Leave computation artifacts in the output |
| Redact or mask sensitive fields per the consumer's permissions | Skip format conversion because "it's almost the same" |
| Validate the output against the consumer's schema | Assume the consumer can handle internal types |

```python
# ✅ Good output stage: convert computation format to consumer format
def to_api_response(records: list[DiscountedRecord]) -> list[dict]:
    """Convert internal records to the API response format.

    The API consumer expects denormalized JSON with customer details
    embedded, not joined via normalized foreign keys.
    """
    results = []
    for record in sorted(records, key=lambda r: r.customer_id):
        customer = customer_cache.get(record.customer_id)
        results.append({
            "customer": {
                "id": record.customer_id,
                "name": customer.name,
                "tier": customer.tier,
            },
            "item": record.sku,
            "quantity": record.quantity,
            "price": record.price,
            "total": record.quantity * record.price if record.price is not None else None,
        })
    return results
```

## When the Three-Stage Model Applies

This model is not just for data engineering pipelines. It applies to:

| Context | Ingestion | Transformation | Output |
|---|---|---|---|
| **ETL pipeline** | Read from source DB/files, validate schema | Business logic, joins, aggregation | Write to warehouse, generate reports |
| **REST API handler** | Parse/validate request body | Apply business logic | Format JSON response |
| **CLI tool** | Parse CLI args, validate file paths | Core processing | Print/save results |
| **Data science notebook** | Load CSVs/APIs, validate columns | Feature engineering, models | Export results, charts |
| **Event-driven system** | Deserialize message, validate envelope | Enrich with context, route | Publish to downstream topic |
| **UI component** | Receive props, validate types | Compute derived state | Render/emit output props |

In each case, the boundary between stages is a deliberate design choice. Code
reviewers should be able to point to any line and identify which stage it belongs to.

## Temporal Coupling

Stages should be decoupled by intermediate storage so they can run independently:

```
Bad (tight coupling):
  ingest() → transform() → output()   # all in one function, must succeed together

Good (decoupled):
  ingest() → write to temp storage →
  transform() reads from storage → write to intermediate storage →
  output() reads from storage → write to final destination
```

Decoupled stages enable:

- **Independent testing:** run transformation on a snapshot of ingestion output
- **Partial replay:** re-run only the output stage after fixing a formatting bug
- **Parallel execution:** transform multiple partitions simultaneously
- **Resilience:** a failure in output doesn't lose transformation work already done

The storage between stages can be files on disk, database tables, message queues,
or in-memory buffers — what matters is the *contract at the interface*, not the
underlying storage technology.

## Batching vs. Streaming

Make an explicit architectural decision about how data moves through the stages:

| Mode | When to use | Stage implications |
|---|---|---|
| **Batch** | Processing large volumes on a schedule (hourly, daily) | Each stage reads all records, processes, writes all results. Idempotency is critical. |
| **Streaming** | Low-latency processing of continuous events | Each record flows through all stages individually. State management and ordering matter. |
| **Micro-batch** | Balance between latency and throughput | Small batches flow through periodically. Offers some batching efficiency with near-real-time latency. |

The three-stage model holds for all modes. The difference is in how each stage
is triggered and what "a unit of work" means (a batch file, a single event, a
windowed collection).

## Testing Pipeline Stages in Isolation

Each stage should be independently testable. This is the pipeline equivalent of
unit testing:

```python
def test_transform_enrich_maps_prices():
    """Test transformation with mocked ingestion output."""
    raw = [RawRecord(customer_id="c1", items=[Item("sku1", 2)])]
    with patch("prices.price_lookup", {"sku1": 9.99}):
        result = enrich_with_pricing(raw)
    assert result[0].price == 9.99

def test_output_formats_for_consumer():
    """Test output independently using mocked transformation results."""
    records = [DiscountedRecord(customer_id="c1", sku="sku1", quantity=2, price=9.99)]
    result = to_api_response(records)
    assert result[0]["customer"]["id"] == "c1"
    assert result[0]["total"] == 19.98
```

See **[testing-guide](../testing-guide/SKILL.md)** for general testing methodology.

---

## Checklist: Architecture Review

When reviewing a data processing design, verify:

**Stage separation**

- [ ] Ingestion validates and logs but does not transform
- [ ] All type conversions and business logic happen in the transformation stage
- [ ] Output is a distinct stage that converts to consumer format
- [ ] No stage mixes the responsibilities of another

**Stage coupling**

- [ ] Stages are decoupled by intermediate storage (files, tables, queues)
- [ ] Each stage can be tested with mocked inputs from the previous stage
- [ ] A failure in one stage does not require re-running upstream stages from scratch
- [ ] The batching vs. streaming decision is explicit and appropriate

**Consumer awareness**

- [ ] The output stage converts to exactly the format the consumer expects
- [ ] Internal computation formats (normalized, graph, memory-optimized) are not leaked to consumers
- [ ] Sensitive fields are redacted per the consumer's permission level

---

## Related Skills

- **[data-contracts](../data-contracts/SKILL.md)** — How to define and enforce contracts at every stage boundary: validation patterns, null handling, schema evolution, and dead-letter queues.
- **[data-pipeline-reliability](../data-pipeline-reliability/SKILL.md)** — Operational concerns for running data pipelines in production: idempotency, replayability, audit trails, and monitoring.
- **[architecture-doc](../architecture-doc/SKILL.md)** — Documenting system architecture, including data flow sections where this three-stage model should be reflected.
- **[dataframe-function-dev](../dataframe-function-dev/SKILL.md)** — Validation and testing patterns for individual transformation-phase functions.
