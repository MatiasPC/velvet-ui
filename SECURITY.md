# Security policy

## Supported versions

Security fixes land on the latest released minor version (currently 0.2.x). Until 1.0, older minors are not patched.

## Reporting a vulnerability

Please report vulnerabilities privately through [GitHub Security Advisories](https://github.com/MatiasPC/velvet-ui/security/advisories/new). Do not open a public issue or discussion for a security problem.

Include the affected version, what you found, and steps to reproduce it. You can expect an acknowledgement within a few days and an update once the report has been assessed. Credit is given in the release notes unless you prefer otherwise.

## Scope

Velvet UI is a UI library with no networking of its own beyond `AsyncImage` calls you configure, and a development CLI (`scripts/velvet.swift`) that downloads component sources from this repository. Reports about that CLI, about unsafe behavior in a component, or about the build and release pipeline are all in scope.
