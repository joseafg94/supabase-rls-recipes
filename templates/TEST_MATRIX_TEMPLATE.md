# <Recipe> Authorization Test Matrix

## Fixtures

| ID | Actor/tenant/resource | Stable fictional identifier |
| --- | --- | --- |
|  |  |  |

## Matrix

| Test ID | DB role | Actor | Command | Target/payload | Expected observation | Expected final state | Threat |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ALLOW-001 |  |  |  |  |  |  |  |
| DENY-001 |  |  |  |  |  |  |  |

## Coverage checks

- [ ] Every supported command has at least one allow and one deny case.
- [ ] Anonymous behavior is explicit.
- [ ] Each tenant direction is tested.
- [ ] Forged owner/tenant/role/path values are tested.
- [ ] Update reassignment and delete boundaries are tested.
- [ ] Empty result, zero affected rows, and policy rejection are distinguished.
- [ ] Denied mutations verify unchanged state.
- [ ] Multiple-policy composition is exercised.
- [ ] Privileged execution is isolated from app-user assertions.
