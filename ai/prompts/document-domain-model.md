---
description: Create a business-focused domain model document
---

Create a domain model document.

Define:

- domain objects, including their names and purposes;
- relationships between domain objects;
- the domain scope and boundaries, including what is explicitly outside the model;
- central business rules, including invariants that must always hold;
- meaningful state transitions where applicable.

Use business language. Avoid technical terms and implementation details.

Make the model as complete, unambiguous, and internally consistent as the available evidence permits. Identify every material gap, ambiguity, contradiction, and unresolved rule; do not silently resolve them.

When applicable:

- state relationship cardinality and ownership where business-relevant;
- name the objects, states, and exceptions to which each rule applies;
- define each state transition's allowed source and target states and its triggering business event;
- include a glossary for terms that could be interpreted differently.

Base the model on existing code and documentation. Clearly distinguish verified facts from assumptions, and list open questions. If the available evidence is insufficient, read relevant code and docs, then ask questions before making unsupported claims.
