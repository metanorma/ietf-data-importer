# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`ietf-data-importer` is a Ruby gem providing offline access to IETF working group and IRTF research group metadata. It ships bundled YAML data and includes web scrapers to refresh it from `datatracker.ietf.org` and `irtf.org`.

## Commands

```sh
bundle install          # install dependencies
bundle exec rake        # run tests (default task = rspec)
bundle exec rspec       # run full test suite
bundle exec rspec spec/ietf/data/importer_spec.rb:45  # run single test by line
bundle exec rubocop     # lint
exe/ietf-data-importer fetch output.yaml             # scrape & write YAML
exe/ietf-data-importer fetch output.json --format=json
exe/ietf-data-importer integrate groups.yaml          # embed YAML into gem
```

## Architecture

Namespace: `Ietf::Data::Importer`

```
lib/ietf/data/importer.rb              # Entry point — autoload, thin facade delegating to GroupCollection
lib/ietf/data/importer/
  version.rb                           # VERSION constant
  group.rb                             # Group model (Lutaml::Model) with predicate methods
  group_collection.rb                  # Rich collection model (Enumerable, query methods, merge, from_file, save)
  groups.yaml                          # Bundled group data (shipped in gem)
  cli.rb                               # Thor CLI (fetch / integrate commands)
  scrapers.rb                          # Scrapers.fetch_all / fetch_ietf / fetch_irtf → GroupCollections
  scrapers/
    base_scraper.rb                    # Abstract: fetch_html, log, build_group, build_collection
    ietf_scraper.rb                    # Scrapes datatracker.ietf.org → GroupCollection
    irtf_scraper.rb                    # Scrapes irtf.org → GroupCollection
```

**Layer separation:**
- **Models** (`Group`, `GroupCollection`) — all data and query logic. GroupCollection includes Enumerable and supports chainable filters returning new GroupCollections (`collection.active.by_type("wg")`).
- **Facade** (`Importer` module) — loads bundled `groups.yaml` via `GroupCollection.from_file`, delegates query methods to the collection for backward-compatible API. Uses `autoload` (following sts-ruby pattern).
- **Scrapers** — each returns a `GroupCollection`. `Scrapers.fetch_all` uses `merge` to combine results. `BaseScraper` provides `build_group`/`build_collection` template methods.
- **CLI** (`Cli`) — thin Thor wrapper calling scraper and collection methods.

**Key design decisions:**
- Models use `lutaml-model` for serialization — attribute declarations + key_value mapping blocks, same as sts-ruby
- GroupCollection filter methods (`by_organization`, `by_type`, `by_area`, `active`, `concluded`) return new GroupCollections, enabling chaining (open/closed principle)
- All facade query methods return GroupCollection; only `groups` returns Array
- `Group` has predicate methods (`active?`, `ietf?`, `working_group?`) — business logic on the model, not in collection filters
- `GroupCollection.merge(other)` combines collections immutably
- `GroupCollection.from_file(path)` / `#save(path, format:)` handle persistence
- Entry point (`exe/ietf-data-importer`) requires the main importer file, triggering autoload — no direct requires in cli.rb
- Tests inject data by stubbing `Importer.collection` — no private state access or `class_variable_set`
- Scrapers are resilient to site layout changes: multiple CSS selectors tried as fallbacks
- Scraper methods return values rather than mutating parameters

## Conventions

- Ruby 3.0+ required
- Frozen string literals everywhere
- Lutaml::Model for all data models (no raw Hash manipulation in the public API)
- Test fixtures in `spec/fixtures/`; specs in `spec/ietf/data/importer/` (group_spec, group_collection_spec, cli_spec, importer_spec)
- Tests stub `Importer.collection` scoped to `:query_tests` context — no global stubs, no private state access
- Rubocop config inherits from riboseinc/oss-guides (remote URL in `.rubocop.yml`)

## Reference Project

The `sts-ruby` project at `../sts-ruby/` demonstrates the canonical patterns for Lutaml::Model-based gems in this org:
- `autoload` for lazy-loading modules/classes
- Each model is a single class in its own file, inheriting `Lutaml::Model::Serializable`
- One file per class; no `private` send or `respond_to?` — rely on typed interfaces
