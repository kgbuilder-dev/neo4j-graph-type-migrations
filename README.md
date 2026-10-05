# Neo4j graph type migrations

Companion repo for the article [**"Schema Migrations for Neo4j Graph Types: Evolving a Knowledge Graph Model Safely"**](https://medium.com/@akkonrad/schema-migrations-for-neo4j-graph-types-evolving-a-knowledge-graph-model-safely-66a2abaac418) (Medium, October 2026).

A small conference knowledge graph whose ontology changes three times. Neo4j graph types (Cypher 25, Enterprise Edition, GA since Neo4j 2026.06) enforce each version; [Neo4j-Migrations](https://github.com/michael-simons/neo4j-migrations) applies the changes in order; zero-row invariant queries check the data after each release. The scripts also check the graph type behaviour the article describes against a real Neo4j Enterprise container (locally, or as a manually triggered GitHub Actions workflow). Verified on Neo4j 2026.09.0 Enterprise with Neo4j-Migrations 4.2.0.

## The model and its changes

| Step | What changes | Migration files |
|---|---|---|
| Starting model | Person, Talk, Topic, Event; the talk's slot lives on `SCHEDULED_AT {room, slot}` | `V1` (`SET`, the only one) |
| Change 1, additive | `Organization` + `WORKS_FOR` | `V2` (`ADD`) |
| Change 2, restructuring | `SCHEDULED_AT` becomes `Session` + `Room` with `PRESENTED_IN`, `IN_ROOM`, `PART_OF` | `V3` expand (`ADD`), `V4` migrate data (batched), `V5` delete old relationships, `V6` drop the old rule |
| Change 3, destructive | employer data and emails removed | `V7` delete data, `V8` `ALTER` Person + `DROP` the rules |

`ontology/` has an [arrows.app](https://arrows.app) diagram of the model after V1, V2, V4 (the expand state, old and new shape side by side), V6 and V8. Same layout in all five: green is added in that step, red is removed, grey is the old shape still in place. `!` after a type means `NOT NULL`.

Schema changes and data changes sit in separate files on purpose: Neo4j does not allow a schema change and a data write in the same transaction, and Neo4j-Migrations runs each file in one transaction by default. Statements with `CALL { ... } IN TRANSACTIONS` (V4) are detected by Neo4j-Migrations and run in an auto-commit transaction. Each batch commits on its own, and a failed migration is not recorded as applied, so V4 uses `MERGE` throughout and can simply run again.

## Run it locally

Requirements: Docker and the [Neo4j-Migrations CLI](https://michael-simons.github.io/neo4j-migrations/current/) (`brew install michael-simons/homebrew-neo4j-migrations/neo4j-migrations`).

```bash
scripts/start-neo4j.sh
scripts/run-migrations.sh
scripts/check-claims.sh
```

`start-neo4j.sh` starts `neo4j:2026.09.0-enterprise` (override with `NEO4J_IMAGE`) with `NEO4J_ACCEPT_LICENSE_AGREEMENT=yes`. Graph types need Enterprise Edition; check that Neo4j's license terms fit your use before running it.

`run-migrations.sh` simulates four releases on a fresh database called `releases` (recreated on every run): it stops at V1, V2 and V4 with `--target V1` etc., loads demo data that matches the model at that point, runs the invariants in `tests/after-V4` before the contract step and those in `tests/final` at the end.

`check-claims.sh` creates one fresh database per claim and checks:

1. `SET` fails when existing data breaks the new graph type.
2. `SET` replaces constraints created before it.
3. `ADD` cannot add a property to an existing element type, and `ALTER` redefines the whole element type (a property left out is no longer checked, a dropped `NOT NULL` is gone).
4. `DROP` removes the rule and keeps the data.
5. A graph type change and a data write cannot share one transaction.
6. After the contract step, writes in the old shape are no longer checked, while declared rules still are.
7. V4 is written with `MERGE` only, so rerunning it after a partial failure creates no duplicate sessions or rooms.

Stop the container with `docker rm -f graph-type-migrations-neo4j`.

## Layout

```
migrations/   V1..V8, applied by Neo4j-Migrations
seed/         demo data loaded after V1 and after V2 (not migrations; a real system gets its data from the application)
tests/        zero-row invariants: after-V4 (before the contract step) and final
ontology/     arrows.app diagrams of the model after V1, V2, V4, V6 and V8
scripts/      start Neo4j, run the release simulation, check the claims
```
