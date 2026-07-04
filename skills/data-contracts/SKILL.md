---
name: data-contracts
description: How to define and enforce data quality contracts at every stage boundary in a data pipeline. Covers validation patterns, type conversion safety, null/sentinel handling, schema evolution, dead-letter queues, and contract testing. Use when implementing any component that receives, transforms, or passes data to another component.
---

# Data Contracts

## Why This Skill Exists

Every boundary between two data processing stages is a *contract* — a set of
mutual expectations about what data looks like, what values are valid, and how
errors are communicated. When these contracts are implicit, systems degrade
silently: nulls propagate undetected, invalid values corrupt downstream
computation, and schema changes break consumers without warning.

**This skill mandates explicit, enforceable contracts at every data boundary.**
Use it whenever you design a function, module, class, service, or pipeline stage
that receives or emits data.

For the higher-level architectural model that separates data flow into ingestion,
transformation, and output stages, see
**[data-pipeline-architecture](../data-pipeline-architecture/SKILL.md)**.

---

## What Is a Data Contract?

A data contract is a formal specification of the data that crosses a boundary.
It answers:

| Question | Example |
|---|---|
| **What fields exist?** | `customer_id`, `order_date`, `items`, `total` |
| **What types are they?** | `string`, `Date`, `list[Item]`, `float` |
| **What values are valid?** | `total >= 0`, `items` is non-empty, `order_date` is not in the future |
| **What nulls are allowed?** | `customer_id` is never null; `discount_code` can be null |
| **What happens on violation?** | Raise exception, log warning, route to dead-letter queue |

A contract applies at every boundary — not just at the system's outer edge. The
ingestion stage has a contract with the outside world; each transformation step
has a contract with the previous step; the output stage has a contract with the
consumer.

---

## Contracts at Ingestion: Validate, Don't Transform

At the ingestion boundary, data enters the system from an external source.
The contract here is narrow: **check that the data is in the expected form; do
not change it.**

```python
# ✅ Validating at the ingestion boundary — no transformation
def ingest(order: dict) -> IngestedOrder:
    required = {"customer_id", "items"}
    missing = required - set(order.keys())
    if missing:
        raise ValidationError(f"Missing required fields: {sorted(missing)}")

    if not isinstance(order.get("customer_id"), str):
        raise ValidationError(
            f"customer_id must be str, got {type(order['customer_id']).__name__}")

    return IngestedOrder(
        customer_id=order["customer_id"],
        items=order["items"],     # unchanged from the raw input
        ingested_at=datetime.now(timezone.utc),
    )
```

Key principle: **the ingested record is in its original form, plus provenance
metadata** (timestamp, source identifier). No type conversions, no defaults
filled in, no business logic applied.

---

## Contracts During Transformation: Validate Every Conversion

In the transformation stage, data changes form. Every change must be
accompanied by validation.

### Rule 1: Type conversion is always paired with validation

```python
# ❌ Bad: type conversion without validation
def parse_date(raw: str) -> date:
    return date.fromisoformat(raw)  # what if raw is "not-a-date"?

# ✅ Good: conversion with validation and explicit error handling
def parse_date(raw: str) -> date:
    try:
        return date.fromisoformat(raw)
    except (ValueError, TypeError) as e:
        raise ValidationError(f"Invalid date '{raw}': {e}") from e
```

### Rule 2: The output of one step must be valid input for the next

Every possible value a transformation function can return must be acceptable
to whatever consumes it. This is the **"no impossible values"** rule.

```python
# ✅ Next step's contract is explicit about what it accepts
def apply_discounts(records: list[PricedRecord]) -> list[DiscountedRecord]:
    """Apply customer discounts to priced records.

    Contract with caller: price can be None (missing price data).
    Contract with next step: price in output can be None; total will also be None.
    """
    for record in records:
        if record.price is None:
            # None is a contractually valid value — pass it through
            yield DiscountedRecord(..., price=None, total=None)
            continue

        if record.price < 0:
            # Negative price violates this function's input contract
            raise ContractViolationError(
                f"Negative price {record.price} for SKU {record.sku}. "
                f"Upstream step violated the contract.")

        discount = get_discount(record.customer_id)
        discounted_price = record.price * (1 - discount)
        yield DiscountedRecord(
            ..., price=discounted_price,
            total=discounted_price * record.quantity)
```

### Rule 3: Document the null-handling contract

Every nullable field in a contract must have a documented policy:

| Policy | When to use | Example |
|---|---|---|
| **Null forbidden** | The field is required; absence is an error | `customer_id` — raise on null |
| **Null pass-through** | Nulls flow through unchanged | `discount_code` — keep null |
| **Null replaced** | Nulls are substituted with a sentinel | `missing_price` → `0.0` with a warning |
| **Null filtered** | Records with null values are removed | Drop rows where `email` is null |

```python
# ✅ Explicit null handling documented per field
def normalize(records: list[PricedRecord]) -> list[NormalizedRecord]:
    """Normalize priced records for downstream aggregation.

    Null-handling contract:
      - price: pass-through (null prices produce null totals)
      - quantity: null forbidden (raise if null)
      - discount_code: null pass-through (optional annotation)
    """
    for r in records:
        if r.quantity is None:
            raise ContractViolationError(
                f"quantity is null for SKU {r.sku}. Quantity must be non-null.")
        yield NormalizedRecord(
            sku=r.sku,
            quantity=r.quantity,
            price=r.price,          # null pass-through
            total=r.price * r.quantity if r.price is not None else None,
            discount_code=r.discount_code,  # null pass-through
        )
```

### Rule 4: Enforce range and domain constraints

Numeric ranges, allowed enum values, and categorical domains are all part of
the contract:

```python
def validate_temperature(celsius: float) -> float:
    if celsius < -273.15:
        raise ContractViolationError(
            f"Temperature {celsius}°C is below absolute zero. "
            f"Valid range is >= -273.15.")
    if celsius > 1e9:
        raise ContractViolationError(
            f"Temperature {celsius}°C exceeds physically plausible maximum.")
    return celsius

def validate_status(status: str) -> str:
    allowed = {"pending", "processing", "shipped", "delivered", "cancelled"}
    if status not in allowed:
        raise ContractViolationError(
            f"Invalid status '{status}'. Allowed values: {sorted(allowed)}")
    return status
```

---

## Schema Evolution

Data schemas change over time. Contracts must account for this.

### Additive changes (backward compatible)

New fields that don't change existing semantics:

```python
# v1 contract
@dataclass
class OrderV1:
    customer_id: str
    items: list[dict]

# v2 contract — additive, backward compatible
@dataclass
class OrderV2:
    customer_id: str
    items: list[dict]
    discount_code: str | None = None  # new field with default
```

### Destructive changes (require versioning)

Changes that alter or remove existing fields require explicit versioning
and a migration strategy:

```python
def consume_order(order: OrderV2) -> ProcessedOrder:
    if order.discount_code is None:
        # Consumer is robust to the field being absent (v1 data)
        pass
    ...
```

Guidelines for schema evolution:

1. **Always add, never remove:** New fields should be optional. Removing a
   required field is a breaking change — version the contract instead.
2. **Deprecate before removing:** Mark fields as deprecated for at least one
   release cycle before removal. Log warnings when deprecated fields are used.
3. **Consumers must be robust to new fields:** The contract should specify that
   unknown fields are ignored, not rejected.
4. **Test with old data:** Every schema version should be tested with data
   produced by all previous versions.

---

## Handling Bad Data: Dead-Letter Queues

Data that violates a contract should not silently disappear or crash the
pipeline. Use a dead-letter queue (DLQ) pattern:

```
                    ┌──────────────┐
Valid data ───────▶│ Next Stage   │
                    └──────────────┘
                    ┌──────────────┐
Invalid data ─────▶│ Dead-Letter  │───▶ alert, inspect, reprocess
                    │ Queue        │
                    └──────────────┘
```

```python
def process_with_dlq(
    records: list[RawRecord],
    dead_letter: list[tuple[RawRecord, str]],
) -> list[TransformedRecord]:
    """Transform records, routing failures to a dead-letter queue.

    The dead-letter queue preserves the original record and the failure
    reason for inspection and reprocessing.
    """
    good: list[TransformedRecord] = []
    for record in records:
        try:
            good.append(transform(record))
        except ContractViolationError as e:
            dead_letter.append((record, str(e)))
            LOGGER.warning("Record %s routed to DLQ: %s", record.id, e)
    return good
```

Key DLQ design principles:

- **Preserve the original input** — the DLQ entry must contain the exact data
  that failed, so it can be reprocessed after the issue is fixed.
- **Include the failure reason** — a human-readable message and, when
  available, structured error metadata (field name, expected vs. actual value).
- **Make the DLQ visible** — log every DLQ entry at warning level; expose a
  metric so operators can monitor the DLQ depth.
- **Don't silently drop** — a record that fails validation should either go to
  the DLQ or cause a hard failure, never be discarded without a trace.

---

## Testing Data Contracts

Test each contract boundary independently. One test per constraint:

```python
# A contract with 3 constraints → 3 tests (one per constraint)

def test_ingestion_rejects_missing_customer_id():
    with pytest.raises(ValidationError, match="customer_id"):
        ingest({"items": []})

def test_ingestion_rejects_wrong_type_for_customer_id():
    with pytest.raises(ValidationError, match="customer_id.*must be str"):
        ingest({"customer_id": 123, "items": []})

def test_ingestion_accepts_valid_payload():
    record = ingest({"customer_id": "c1", "items": [{"sku": "a", "qty": 1}]})
    assert record.customer_id == "c1"
```

When testing contracts between transformation steps, mock the upstream output
and verify that the downstream step produces only contract-compliant results:

```python
def test_transform_produces_contract_compliant_output():
    """Every output value must be valid for the next step's contract."""
    input_records = [PricedRecord(customer_id="c1", sku="a", quantity=2, price=9.99)]
    results = apply_discounts(input_records)
    for r in results:
        # The downstream contract: price is a non-negative float or None
        assert r.price is None or (isinstance(r.price, float) and r.price >= 0)
```

For deeper testing methodology, see
**[testing-guide](../testing-guide/SKILL.md)**.

---

## Contracts at Output: Validate Against Consumer Schema

The output stage has a contract with the *next consumer*. Before emitting data,
validate that it matches what the consumer expects:

```python
def to_api_response(records: list[DiscountedRecord]) -> list[dict]:
    results = []
    for record in records:
        item = {
            "customer": {"id": record.customer_id, "name": customer_cache[record.customer_id].name},
            "item": record.sku,
            "quantity": record.quantity,
            "price": record.price,
            "total": record.price * record.quantity if record.price is not None else None,
        }
        # Validate output before returning
        assert isinstance(item["customer"]["id"], str)
        assert item["quantity"] > 0, f"quantity must be positive, got {item['quantity']}"
        results.append(item)
    return results
```

---

## Schema Validation Libraries

Rather than hand-writing checks, declare contracts declaratively. Schema
validation libraries keep contract logic out of function bodies and make
contracts reusable.

| Library | Language / ecosystem |
|---|---|
| `pandera` | Python (pandas, polars, pyspark) |
| `great_expectations` | Python |
| `pydantic` | Python (typed models with built-in validation) |
| `assertr` | R |
| `validate` | R |

```python
# pydantic: declare the contract as a model
from pydantic import BaseModel, Field, field_validator

class OrderContract(BaseModel):
    customer_id: str
    items: list[dict] = Field(min_length=1)
    order_date: date

    @field_validator("order_date")
    @classmethod
    def not_in_future(cls, v: date) -> date:
        if v > date.today():
            raise ValueError("order_date cannot be in the future")
        return v

# The contract is enforced automatically on construction
order = OrderContract(**raw_payload)  # raises ValidationError on violation
```

---

## Checklist: Contract Review

Before declaring a data boundary complete:

**Contract definition**

- [ ] Every field has a declared type
- [ ] Nullability is explicit for every field
- [ ] Range and domain constraints are enumerated
- [ ] Schema evolution strategy is documented (additive vs. versioned)

**Contract enforcement**

- [ ] Type conversion is always paired with validation
- [ ] Every violation produces a message that states what was expected and what was found
- [ ] Bad data goes to a dead-letter queue or raises a clear error (never silently dropped)
- [ ] The contract with the next stage is verified: no impossible values can cross the boundary

**Testing**

- [ ] One test per contract constraint (missing fields, wrong types, out-of-range values)
- [ ] Each transformation step is tested with mocked upstream output
- [ ] Old-schema data is tested against new-schema consumers

---

## Related Skills

- **[data-pipeline-architecture](../data-pipeline-architecture/SKILL.md)** — The three-stage model (ingestion → transformation → output) that these contracts exist to enforce.
- **[data-pipeline-reliability](../data-pipeline-reliability/SKILL.md)** — Production concerns: idempotency, replayability, audit trails, and monitoring.
- **[dataframe-function-dev](../dataframe-function-dev/SKILL.md)** — Validation and testing patterns for individual dataframe functions, which are transformation-phase components.
- **[testing-guide](../testing-guide/SKILL.md)** — General testing methodology, including the None-One-Many parameter principle.
- **[security-guardrails](../security-guardrails/SKILL.md)** — Security-oriented input validation and sanitization, which complements domain-level contract validation.
