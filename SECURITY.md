# Security Policy

## Supported Versions

We actively support the following versions of Photonic Ring with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.0.2   | :white_check_mark: |
| 0.0.1   | :white_check_mark: |
| < 0.0.1 | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

**Do NOT create a public GitHub issue for security vulnerabilities.**

Instead, please report security issues via one of the following methods:

1. **Email (Preferred)**: Send details to [phanbaoduy0503@gmail.com](mailto:phanbaoduy0503@gmail.com)
   - Subject: `[SECURITY] Photonic Ring - Brief Description`
2. **GitHub Private Vulnerability Reporting**: Use GitHub's private vulnerability reporting feature if available.

### What to Include

Please include the following information in your report:

- **Description**: A clear description of the vulnerability.
- **Affected Version(s)**: Which version(s) are affected.
- **Steps to Reproduce**: Detailed steps to reproduce the issue.
- **Impact Assessment**: What could an attacker potentially achieve?
- **Proof of Concept**: If possible, include code or screenshots demonstrating the vulnerability.

### Response Timeline

| Action                   | Timeframe                                                            |
| ------------------------ | -------------------------------------------------------------------- |
| Acknowledgment of report | Within 48 hours                                                      |
| Initial assessment       | Within 7 days                                                        |
| Status update            | Every 14 days until resolved                                         |
| Fix release              | Depends on severity (Critical: ASAP, High: 30 days, Medium: 90 days) |

### Security Best Practices for Users

When using Photonic Ring in your projects:

1. **Keep Updated**: Always use the latest version to benefit from security patches.
2. **Verify Downloads**: Only download releases from the official GitHub repository.
3. **Review Dependencies**: Regularly check for updates in the Rust dependencies (`cargo update`).

### Scope

This security policy covers:

- The Photonic Ring GDExtension plugin
- The Rust source code in the `rust/` directory
- The GDScript code in the `addons/` directory

This policy does NOT cover:

- Third-party dependencies (report to their respective maintainers)
- The Godot Engine itself (report to the Godot Security Team)

## Security Features

Photonic Ring is designed with security in mind:

- **Memory Safety**: Core logic written in Rust, eliminating common memory vulnerabilities.
- **No Network Access**: The plugin operates entirely offline with no network capabilities.
- **Sandboxed Execution**: Runs within Godot's plugin sandbox.
- **Open Source**: Full transparency allows community security audits.

## Acknowledgments

We appreciate security researchers who help keep Photonic Ring safe. Responsible disclosure will be acknowledged in our release notes (with your permission).

---

Thank you for helping keep Photonic Ring and its users safe! 🛡️
