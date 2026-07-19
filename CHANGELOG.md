# Capacity Manager (CE) v1.0 Changelog

All notable changes to Capacity Manager (CE) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Capacity Manager (Pro) release notes are maintained separately in
`CHANGELOG.capman-pro.md`.

## [1.0.0] - 2026-07-18

### Added

- Local Docker Compose installation for the Community Edition application and
  PostgreSQL databases.
- Upgrade and build rollback workflows that preserve local configuration,
  database volumes, and workspace data.
- Licence request, activation, renewal, validation, and sign-out workflows for
  CE releases where activation is enabled.

### Changed

- CE container images are distributed through GitHub Container Registry.

### Security

- Documented the accepted temporary risk from `CVE-2025-66959` and
  `CVE-2025-66960` in the pinned `ollama==0.6.2` dependency while no confirmed
  fixed upstream release is available.

### Removed

- Agent-facing automation APIs and the MCP bridge are not included in CE; they
  remain Capacity Manager (Pro) features.

[1.0.0]: https://github.com/Silicon-Insights/capman-ce/releases
