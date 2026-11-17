# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/setup            # Install deps, copy env files, prepare DB, start dev server (--reset also resets the DB)
bin/dev              # Start development server only
bin/ci               # Full CI pipeline (rubocop → bundler-audit → brakeman → rspec)
bin/rubocop          # Lint
bin/brakeman         # Security static analysis
bin/bundler-audit    # Gem vulnerability scan
bundle exec sidekiq  # Start Sidekiq worker (bin/jobs is the opt-in Solid Queue supervisor)
bundle exec rspec                              # Run all tests
bundle exec rspec spec/path/to/file_spec.rb   # Run single file
bundle exec rspec spec/path/to/file_spec.rb:5 # Run single example
```

## Architecture

This is a **Rails 8 API-only app** (no views) with [Grape](https://github.com/ruby-grape/grape) as the API framework.

### API Layer (`app/api/`)

All HTTP endpoints live in Grape, not Rails controllers.

- `app/api/api_root.rb` — Root Grape::API with Swagger config mounted
- `app/api/v1/api.rb` — V1 namespace; defines `authenticate_request!` and `current_user` helpers shared across all resources
- `app/api/v1/resources/` — One file per resource (e.g., `auth.rb`); auto-mounted by the generator
- `app/api/v1/entities/` — Grape::Entity classes for response serialization

Routes are mounted in `config/routes.rb`:
- `mount ApiRoot => "/"` — all Grape endpoints under `/api/v1/`
- `/swagger` — Swagger UI (dev only)
- `/sidekiq` — Sidekiq Web dashboard

### Authentication

JWT-based auth via `app/services/jwt_service.rb`. Tokens use a JTI claim stored in the database for invalidation on logout. The `authenticate_request!` Grape helper validates `Authorization: Bearer <token>` headers. Requires `JWT_SECRET` env var.

### Error Handling

A shared concern (`app/controllers/concerns/error_handler.rb`) is included into the Grape API. It provides rescue handlers for ActiveRecord errors, Grape validation errors, and JWT errors (`JwtExpiredError`, `JwtDecodeError`, `JwtVerificationError`). Rollbar is called on 5xx errors if `ROLLBAR_ACCESS_TOKEN` is set.

### Generating a New Resource

```bash
rails generate grape_resource ResourceName field:type field:type
```

This creates the resource file, entity, spec, and auto-mounts the resource in `app/api/v1/api.rb`.

### Background Jobs

Sidekiq with Redis. Queues: `critical`, `default`, `mailers`, `maintenance` (defined in `config/initializers/sidekiq.rb`). Scheduler loads `config/scheduler/#{Rails.env}.yml` on Sidekiq startup, if that file exists (the directory only has a `.keep` for now).

Active Job also runs on Sidekiq (`:test` adapter in tests). Solid Queue is opt-in — see README "Background Jobs" for the deploy setup and how to switch.

### Testing

RSpec only (no `test/` dir, no fixtures — FactoryBot). `spec/rails_helper.rb` auto-requires `spec/support/**/*.rb` (FactoryBot, Shoulda Matchers, Bullet, SimpleCov, `Sidekiq::Job.clear_all`). Specs run in random order; `spec/examples.txt` enables `--only-failures`. Request specs get `HelpersConfig`: `sign_in(user)` returns a JWT, `authenticate_request(user)` returns the `Authorization` header, plus `response_body`.

### Conventions

- Use hash enums (`{ user: 0, admin: 1 }`) so reordering values can't change stored integers.
- Frozen string literals at the top of `.rb` files in `app/`, `lib/` and `spec/` (RuboCop enforces it there; `rubocop-rails-suite` excludes `config/`).
- `bin/rails setup:copy_env` (run by `bin/setup`) deliberately has no `:environment` dependency, because booting requires `JWT_SECRET` from the file it creates.

### Key Environment Variables

| Variable | Purpose |
|---|---|
| `JWT_SECRET` | Required — signs JWT tokens |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | DB credentials |
| `REDIS_CACHE_URL` / `REDIS_SIDEKIQ_URL` / `REDIS_CABLE_URL` | Redis connections |
| `SIDEKIQ_USERNAME` / `SIDEKIQ_PASSWORD` | Sidekiq Web UI auth |
| `ROLLBAR_ACCESS_TOKEN` | Optional error tracking |
| `SCOUT_KEY` | Optional APM |

Copy `.env.development` and `.env.test` from their templates before first run.

### Pagination

Uses [Pagy](https://github.com/ddnexus/pagy). Pass `page` and `per_page` query params. A Pagy helper is included in the V1 API.
