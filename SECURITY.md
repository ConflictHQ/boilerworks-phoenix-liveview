# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Boilerworks, please report it responsibly.

**Do not open a public issue.**

Instead, email **security@weareconflict.com** with:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge your report within 48 hours and aim to release a fix within 7 days for critical issues.

## Supported Versions

| Version | Supported |
| ------- | --------- |
| latest  | Yes       |

## Security Best Practices

When deploying Boilerworks:

- Change all default credentials (Postgres user/password, seeded admin login)
- Generate a strong `SECRET_KEY_BASE` with `mix phx.gen.secret` — never deploy the dev default
- Set `DATABASE_URL` to production credentials; do not reuse the compose defaults
- Set `PHX_HOST` to your domain and serve over HTTPS only
- Run with `MIX_ENV=prod` and keep `.env` files out of version control
