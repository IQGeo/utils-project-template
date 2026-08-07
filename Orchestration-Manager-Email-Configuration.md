# Orchestration Manager — Email Configuration

The `EMAIL` step type sends email during flow execution. It supports both cloud-hosted
deployments (AWS SES) and on-premise/self-managed deployments (any SMTP server) through a
single step configuration. The choice of provider and the sending identity are configured
globally on the **Go worker** via environment variables, so flow authors only specify the
message content per step.

## Environment variables

Email configuration is read once by the worker at startup. If `OM_EMAIL_PROVIDER` is
unset, email sending is disabled and `EMAIL` steps fail with `EMAIL_NOT_CONFIGURED`. If
`OM_EMAIL_PROVIDER` is set, the worker **fails to start** if a required variable for the
selected provider is missing, so misconfiguration is caught immediately rather than at
first send.

### Shared (all providers)

| Variable             | Required | Default | Description                                                               |
| -------------------- | -------- | ------- | ------------------------------------------------------------------------- |
| `OM_EMAIL_PROVIDER`  | No       | —       | Transport to use: `ses` or `smtp`. Unset to disable email sending.        |
| `OM_EMAIL_FROM`      | Yes      | —       | Envelope/From address all mail is sent from. Must be a verified identity. |
| `OM_EMAIL_FROM_NAME` | No       | —       | Default display name for the From header. Overridable per step.           |
| `OM_EMAIL_REPLY_TO`  | No       | —       | Default Reply-To address. Overridable per step.                           |

### AWS SES (`OM_EMAIL_PROVIDER=ses`)

Used for cloud-hosted deployments. The worker uses the standard AWS SDK credential chain
(environment variables, shared config, or instance/role credentials), so explicit access
keys are only needed where the chain cannot resolve them automatically.

| Variable                   | Required | Default | Description                                                                                    |
| -------------------------- | -------- | ------- | ---------------------------------------------------------------------------------------------- |
| `AWS_REGION`               | Yes\*    | —       | AWS region of the SES endpoint. `AWS_DEFAULT_REGION` is accepted as a fallback.                |
| `OM_SES_CONFIGURATION_SET` | No       | —       | SES configuration set name, for dedicated IP pools, event publishing, and reputation tracking. |
| `AWS_ENDPOINT_URL`         | No       | —       | Override the SES endpoint. Set this to point at a local emulator during development.           |
| `AWS_ACCESS_KEY_ID`        | No\*\*   | —       | AWS access key. Resolved via the standard credential chain if not set explicitly.              |
| `AWS_SECRET_ACCESS_KEY`    | No\*\*   | —       | AWS secret key. Resolved via the standard credential chain if not set explicitly.              |

\* Either `AWS_REGION` or `AWS_DEFAULT_REGION` must be set.

\*\* Required only if the AWS SDK credential chain cannot otherwise resolve credentials
(e.g. no instance role).

### SMTP (`OM_EMAIL_PROVIDER=smtp`)

Used for on-premise deployments or any standards-compliant SMTP relay. Supports the common
TLS and authentication modes.

| Variable           | Required | Default    | Description                                                         |
| ------------------ | -------- | ---------- | ------------------------------------------------------------------- |
| `OM_SMTP_HOST`     | Yes      | —          | SMTP server hostname.                                               |
| `OM_SMTP_PORT`     | No       | `587`      | SMTP server port.                                                   |
| `OM_SMTP_TLS`      | No       | `starttls` | TLS mode: `none`, `starttls`, or `tls` (implicit TLS).              |
| `OM_SMTP_AUTH`     | No       | `plain`    | Authentication mechanism: `plain`, `login`, `cram-md5`, or `none`. |
| `OM_SMTP_USERNAME` | No\*     | —          | Username for SMTP authentication.                                   |
| `OM_SMTP_PASSWORD` | No\*     | —          | Password for SMTP authentication. Treat as a secret.                |
| `OM_SMTP_DOMAIN`   | No       | —          | Domain announced in the SMTP `HELO`/`EHLO` greeting.                |

\* Required when `OM_SMTP_AUTH` is anything other than `none`.
