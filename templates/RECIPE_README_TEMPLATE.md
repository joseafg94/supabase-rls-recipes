# <Recipe title>

## Problem

<One authorization problem this fixture solves.>

## Threat model

- Assets:
- Actors:
- Attacker goals:
- Required controls:
- Out of scope:

## Assumptions

<Auth, grants, tenant lifecycle, claim freshness, and privileged-access assumptions.>

## Schema

<Tables, keys, indexes, and which relationships are trusted.>

## Authorization rules

| Actor | Command | Target | Expected | Reason |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

## Policy explanation

<Explain each operation's `USING`/`WITH CHECK`, roles, grants, and final combined condition.>

## Expected allow cases

- [ ] <Actor → command → target → exact effect>

## Expected deny cases

- [ ] <Actor → command → target → empty result, zero rows, or rejection; protected state unchanged>

## Run locally

```text
<Commands verified for the current toolchain>
```

## Common mistakes

- <Recipe-specific failure and why the tests catch it.>

## Limitations

- <What this fixture does not authorize or protect.>

## Production considerations

<Grants, migrations, indexes, scale, drift, observability, version assumptions, and privileged paths.>
