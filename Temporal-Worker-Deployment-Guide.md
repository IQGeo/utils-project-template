# Temporal Worker Deployment Guide

> **Scope.** This guide covers two recurring operational tasks:
>
> 1. **[Adding a new client cluster](#part-1--adding-a-new-client-cluster)** — registering a
>    new Kubernetes cluster's OIDC issuer on the shared OpenBao and Temporal servers so its
>    workloads can authenticate.
> 2. **[Adding a new tenant](#part-2--adding-a-new-tenant)** — onboarding a new tenant
>    (Temporal namespace + OpenBao child namespace + `temporal-om-worker`) onto a cluster
>    that is already trusted.
>
> For OpenBao server deployment, see the
> [OpenBao Standalone Deployment Guide](./OpenBao-Standalone-Deployment-Guide).

## Mental Model: What "Onboarding" Actually Means

The client cluster and the server clusters never peer at the network level. Every client
reaches the OpenBao and Temporal servers over their **public TLS ingress** endpoints. The
only thing that has to be established is **trust in the client's identity** — its EKS OIDC
issuer — so the servers will accept the short-lived, projected ServiceAccount JWTs the
client's pods mint.

```
                         ┌──────────────────────────┐
                         │ A NEW CLIENT CLUSTER      │
                         │  pods mint projected SA   │
                         │  tokens (aud: temporal /  │
                         │  openbao) signed by the   │
                         │  cluster's OIDC issuer     │
                         └───────────┬──────────────┘
            HTTPS :443 (JWT auth)    │    gRPC :443 (Bearer token)
        ┌────────────────────────────┼────────────────────────────┐
        ▼                            │                             ▼
┌──────────────────────┐            │            ┌──────────────────────────┐
│ OpenBao server       │            │            │ Temporal server          │
│  trusts issuer via   │            │            │  trusts issuer via       │
│  auth/cluster-<name> │            │            │  authorization.jwksUris  │
│  + child ns <name>-* │            │            │  + claim-mapper grants   │
└──────────────────────┘            │            └──────────────────────────┘
```

**Onboarding a cluster = registering its OIDC issuer in two places** (OpenBao JWT auth
mount + Temporal JWKS list).

**Onboarding a tenant = creating the per-tenant namespaces and deploying its worker** on
a cluster whose issuer is already trusted.

---

# Part 1 — Adding a New Client Cluster

Use this when onboarding a Kubernetes cluster that has **never** sent tokens to the shared
servers before. Adding a tenant to an already-trusted cluster does **not** require these
steps — skip to [Part 2](#part-2--adding-a-new-tenant).

## Prerequisites

| Requirement | Why |
|-------------|-----|
| `kubectl` context for the new cluster | Mint tokens, create secrets, apply workloads |
| `helm` + `kubectl` access to the **OpenBao** cluster | Append the cluster to the onboarding release |
| `helm` + `kubectl` access to the **Temporal** cluster | Append the JWKS URI to the Temporal server |
| The new cluster's **EKS OIDC issuer URL** | Identity root of trust (auto-discoverable) |
| vault-agent injector installed on the new cluster | Injects the OpenBao auth sidecar into pods |

## Step 1 — Discover the cluster's OIDC issuer

The issuer is the `iss` claim of any projected SA token minted in the cluster. Mint a
throwaway token and decode it (this is read-only — `TokenRequest` persists nothing):

```bash
NEW_KUBECONFIG=./new-cluster.yaml
NS=default          # the k8s namespace the workloads run in

TOKEN="$(kubectl --kubeconfig="$NEW_KUBECONFIG" -n "$NS" \
          create token default --audience=openbao --duration=600s)"

echo "$TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq -r '.iss'
# → https://oidc.eks.<region>.amazonaws.com/id/<CLUSTER_ID>
```

Record two derived values used everywhere below:

| Value | Definition | Example |
|-------|------------|---------|
| `OIDC_ISSUER` | the `iss` claim above | `https://oidc.eks.eu-west-1.amazonaws.com/id/<CLUSTER_ID>` |
| `JWKS_URI` | `${OIDC_ISSUER%/}/keys` | `…/id/<CLUSTER_ID>/keys` |

Pick a stable **logical cluster name** (`CLUSTER_NAME`). It must stay consistent across
re-runs — it becomes the OpenBao auth mount path `auth/cluster-<CLUSTER_NAME>` and the
child namespace prefix `<CLUSTER_NAME>-<ns>`.

> **Already trusted?** If the discovered issuer already has an OpenBao auth mount and
> Temporal JWKS entry, skip Steps 2–3 and go straight to
> [Part 2](#part-2--adding-a-new-tenant).

## Step 2 — Trust the issuer on OpenBao

Append the new cluster to the OpenBao onboarding release. This is **append-only** —
read the live values first so existing clusters are never replaced.

```bash
OPENBAO_KUBECONFIG=./openbao-cluster.yaml
OPENBAO_NS=<openbao-namespace>
ONBOARD_RELEASE=<onboarding-release-name>

# 1. Capture the live values (preserves address, CA secret, existing clusters)
helm --kubeconfig="$OPENBAO_KUBECONFIG" -n "$OPENBAO_NS" \
  get values "$ONBOARD_RELEASE" -o yaml > /tmp/onboarding-values.yaml

# 2. Append the new cluster entry to .clusters
yq -P '.clusters += [{"name":"'"$CLUSTER_NAME"'","issuer":"'"$OIDC_ISSUER"'","tenants":["'"$NS"'"]}]' \
  /tmp/onboarding-values.yaml > /tmp/onboarding-values-merged.yaml

# 3. Upgrade
helm --kubeconfig="$OPENBAO_KUBECONFIG" -n "$OPENBAO_NS" \
  upgrade "$ONBOARD_RELEASE" <onboarding-chart-ref> \
  --reuse-values -f /tmp/onboarding-values-merged.yaml --timeout 5m --wait

# 4. Trigger an immediate reconcile (otherwise wait for the CronJob schedule)
CRONJOB="$(kubectl --kubeconfig="$OPENBAO_KUBECONFIG" -n "$OPENBAO_NS" \
  get cronjob -o name | grep -i onboard | head -n1 | sed 's#.*/##')"
kubectl --kubeconfig="$OPENBAO_KUBECONFIG" -n "$OPENBAO_NS" \
  create job "reconcile-$CLUSTER_NAME-$(date +%s)" --from="cronjob/$CRONJOB"
```

The onboarding job provisions, for the new cluster:

- a JWT auth mount **`auth/cluster-<CLUSTER_NAME>`** bound to `OIDC_ISSUER`
- a **`tenant`** role on that mount
- per-tenant OpenBao **child namespaces `<CLUSTER_NAME>-<ns>`** with tenant policies

**Verify:**

```bash
kubectl --kubeconfig="$OPENBAO_KUBECONFIG" -n "$OPENBAO_NS" exec <openbao-pod> -- \
  bao auth list | grep "cluster-$CLUSTER_NAME"
```

## Step 3 — Trust the issuer's JWKS on Temporal

Append the cluster's `JWKS_URI` to the Temporal server's authorization config. Also
**append-only**; this upgrade **restarts the Temporal server pods**, so do it in a
maintenance window.

```bash
TEMPORAL_KUBECONFIG=./temporal-cluster.yaml
TEMPORAL_NS=temporal-system
TEMPORAL_RELEASE=temporal
TEMPORAL_CHART=<temporal-chart-ref>

# 1. Capture live values, read current jwksUris
helm --kubeconfig="$TEMPORAL_KUBECONFIG" -n "$TEMPORAL_NS" \
  get values "$TEMPORAL_RELEASE" -o yaml > /tmp/temporal-values.yaml

# 2. Append the new JWKS URI (unique)
yq -P '.server.config.authorization.jwksUris =
       ((.server.config.authorization.jwksUris // []) + ["'"$JWKS_URI"'"] | unique)' \
  /tmp/temporal-values.yaml > /tmp/temporal-values-merged.yaml

# 3. Upgrade (restarts server pods)
helm --kubeconfig="$TEMPORAL_KUBECONFIG" -n "$TEMPORAL_NS" \
  upgrade "$TEMPORAL_RELEASE" "$TEMPORAL_CHART" \
  --reuse-values -f /tmp/temporal-values-merged.yaml --timeout 15m --wait
```

> **claim-mapper note.** Trusting the JWKS lets Temporal *verify the signature*. A
> verified token still gets **no permissions** unless its SA follows the
> `tenant-<slug>-temporal` naming convention **or** has an explicit
> `PLATFORM_SA_MAPPINGS` entry — see Step 4.

## Step 4 — Map any non-convention ServiceAccounts (if needed)

Workloads not named `tenant-<slug>-temporal` (e.g. a platform appserver that starts
workflows) need an explicit grant. `PLATFORM_SA_MAPPINGS` is a comma-separated
`ns/sa:namespace` list in `server.additionalEnv`:

```text
default/myapp-appserver:acme-prod,default/myapp-lrt-worker:acme-prod
```

Add the entries to `server.additionalEnv` and upgrade the Temporal release with the same
append-only pattern as Step 3. Workers whose SA already follows `tenant-<slug>-temporal`
need **no** entry here.

## Step 5 — Install the vault-agent injector on the new cluster

```bash
helm --kubeconfig="$NEW_KUBECONFIG" repo add hashicorp https://helm.releases.hashicorp.com
helm --kubeconfig="$NEW_KUBECONFIG" install vault hashicorp/vault \
  --set injector.enabled=true --set server.enabled=false \
  -n vault-system --create-namespace
```

## Step 6 — Cluster onboarding checklist

| ✓ | Item |
|---|------|
| ☐ | OIDC issuer discovered and recorded |
| ☐ | Stable `CLUSTER_NAME` chosen |
| ☐ | OpenBao `auth/cluster-<name>` mount + `tenant` role + child ns created (Step 2) |
| ☐ | Temporal `jwksUris` includes the cluster's JWKS URI (Step 3) |
| ☐ | `PLATFORM_SA_MAPPINGS` updated for any non-convention SAs (Step 4) |
| ☐ | vault-agent injector running on the cluster (Step 5) |

---

# Part 2 — Adding a New Tenant

Use this on a cluster whose OIDC issuer is **already trusted**. A "tenant" gets its own
isolated Temporal namespace, its own OpenBao child namespace, and its own
`temporal-om-worker`.

> **Naming rule that makes everything else free.** Set the worker's
> **`slug` = its Temporal namespace name**, and name its ServiceAccount
> **`tenant-<slug>-temporal`**. The claim-mapper grants the worker read/write/worker
> on namespace `<slug>` automatically — **no `PLATFORM_SA_MAPPINGS` entry required.**

## Option A — Declarative (temporal-tenant-controller) — preferred

If the `temporal-tenant-controller` is running on the Temporal cluster, a single
`TemporalTenant` Custom Resource drives the whole reconcile — it creates the Temporal
namespace and the OpenBao child namespace + policies.

```bash
kubectl --kubeconfig=./temporal-cluster.yaml apply -f - <<EOF
apiVersion: iqgeo.com/v1
kind: TemporalTenant
metadata:
  # Cluster-scoped resource — do not set metadata.namespace.
  name: acme-prod
spec:
  slug: acme-prod
  tier: standard
  retentionDays: 3
  limits:
    rps: 400
    rpsPerInstance: 200
    visibilityRPS: 100
EOF

# Watch the controller reconcile it
kubectl --kubeconfig=./temporal-cluster.yaml -n temporal-tenant-controller-system \
  logs -l app.kubernetes.io/name=temporal-tenant-controller -f
```

Then continue at [Step 3 — Seed the encryption key](#step-3--seed-the-data-converter-encryption-key).

## Option B — Imperative (no controller)

### Step 1 — Provision the Temporal namespace

```bash
SLUG=acme-prod
FRONTEND=temporal-frontend.temporal-system.svc.cluster.local:7233

kubectl --kubeconfig=./temporal-cluster.yaml -n temporal-system \
  rollout status deploy/temporal-admintools --timeout=120s

kubectl --kubeconfig=./temporal-cluster.yaml -n temporal-system exec deploy/temporal-admintools -- sh -c \
  "temporal operator namespace describe -n '$SLUG' --address '$FRONTEND' \
   || temporal operator namespace create -n '$SLUG' --address '$FRONTEND' --retention 3d"
```

Register OM custom search attributes (idempotent):

```bash
kubectl --kubeconfig=./temporal-cluster.yaml -n temporal-system exec deploy/temporal-admintools -- \
  temporal operator search-attribute create -n "$SLUG" --address "$FRONTEND" \
    --name FlowId --type Keyword \
    --name FlowRunStatus --type Keyword
```

### Step 2 — Ensure the OpenBao tenant namespace exists

Append the tenant to the cluster's entry in the onboarding values and reconcile
(append-only, same pattern as Part 1 Step 2):

```bash
yq -P '(.clusters[] | select(.name=="'"$CLUSTER_NAME"'").tenants) +=
       ["'"$NS"'"] | (.clusters[] | select(.name=="'"$CLUSTER_NAME"'").tenants) |= unique' \
  /tmp/onboarding-values.yaml > /tmp/onboarding-values-merged.yaml
# then helm upgrade and trigger reconcile as in Part 1 Step 2
```

Resulting child namespace: **`<CLUSTER_NAME>-<ns>`**.

## Step 3 — Seed the data-converter encryption key

The `temporal-om-worker` and the platform's `flow_result_decryptor` encrypt Temporal
payloads with an AES-256 key stored at
**`secret/data/om/encryption/temporal-history`** in the **tenant's OpenBao namespace**.
The worker **fails closed** on startup if the key is missing (OpenBao 404), so seed it
**before** installing the worker.

- Authenticate via the same JWT mount the workloads use — **no admin token required**.
- The seed **must be idempotent**: never rotate an existing key, or already-encrypted
  workflow history becomes undecryptable.

## Step 4 — Deploy temporal-om-worker

```bash
SLUG=acme-prod          # MUST equal the Temporal namespace
CLUSTER=<cluster-name>  # logical cluster name from Part 1

helm --kubeconfig="$NEW_KUBECONFIG" upgrade --install temporal-om-worker <worker-chart-ref> \
  -n "$SLUG" --create-namespace \
  --set slug="$SLUG" \
  --set image.repository=<registry>/temporal-om-worker \
  --set image.tag=<version> \
  --set 'imagePullSecrets[0].name=container-registry' \
  --set serviceAccount.create=true \
  --set serviceAccount.name="tenant-$SLUG-temporal" \
  --set temporal.address="<temporal-ingress>:443" \
  --set temporal.namespace="$SLUG" \
  --set openbao.enabled=true \
  --set openbao.authType=jwt \
  --set openbao.address="https://<openbao-ingress>" \
  --set openbao.authPath="auth/cluster-$CLUSTER" \
  --set openbao.role=tenant \
  --set openbao.namespace="$CLUSTER-$SLUG" \
  --set database.host=<rds-endpoint> \
  --set database.name=<db-name> \
  --set database.username=postgres \
  --set database.existingSecret=db-credentials \
  --set database.secretKey=password \
  --timeout 10m --wait
```

> **No explicit Temporal TLS flag.** The Temporal Go SDK auto-enables TLS once token
> credentials are configured, so the `:443` gRPC ingress needs no `temporal.tls=true`.

## Step 5 — Verify the tenant

```bash
# Worker pod should be 2/2 (worker + vault-agent sidecar)
kubectl --kubeconfig="$NEW_KUBECONFIG" -n "$SLUG" get pods -l app.kubernetes.io/name=temporal-om-worker

# vault-agent shows a successful JWT login
kubectl --kubeconfig="$NEW_KUBECONFIG" -n "$SLUG" \
  logs -l app.kubernetes.io/name=temporal-om-worker -c vault-agent

# worker shows "Connected to Temporal" and begins polling its namespace
kubectl --kubeconfig="$NEW_KUBECONFIG" -n "$SLUG" \
  logs -l app.kubernetes.io/name=temporal-om-worker -c worker
```

## Step 6 — Tenant onboarding checklist

| ✓ | Item |
|---|------|
| ☐ | Temporal namespace `<slug>` exists (controller reconciled or admintools-created) |
| ☐ | OM search attributes registered on `<slug>` |
| ☐ | OpenBao child namespace `<cluster>-<ns>` exists with tenant policies |
| ☐ | Encryption key seeded at `secret/data/om/encryption/temporal-history` (idempotent) |
| ☐ | Worker SA named `tenant-<slug>-temporal` **or** `PLATFORM_SA_MAPPINGS` entry added |
| ☐ | temporal-om-worker deployed, pod 2/2, polling its namespace |

---

## Removing a Tenant

```bash
# Client cluster — remove the worker
helm --kubeconfig="$NEW_KUBECONFIG" uninstall temporal-om-worker -n "$SLUG"

# Server cluster — the controller cleans up Temporal ns + OpenBao on Custom Resource delete
kubectl --kubeconfig=./temporal-cluster.yaml delete temporaltenant "$SLUG"
```

> Do **not** delete the cluster's OpenBao auth mount or Temporal JWKS entry when
> removing a single tenant — other tenants on the same cluster depend on them. Only
> remove cluster-level trust when **decommissioning the entire cluster**.

### Tenant Custom Resource lifecycle

The `temporal-tenant-controller` drives a `TemporalTenant` Custom Resource through
phases; deletion is **not** instantaneous because in-flight workflows and history
retention must be honoured:

| Phase | Meaning |
|-------|---------|
| `active` | Normal operation; namespace reconciled |
| `suspended` | Workers paused; namespace retained |
| `draining` | New workflows blocked; in-flight allowed to finish |
| `retention_hold` | No new work; history kept until retention window elapses |
| `delete_requested` | Finalizer running cleanup (Temporal ns + OpenBao child ns/key) |

> **Encryption-key ordering caveat:** if you need post-deletion audit of the tenant's
> historical workflows, retain the encryption key until that data has aged out of
> Temporal retention. Deleting the key first makes retained history permanently
> undecryptable.

---

## Quick Reference: Cluster vs. Tenant

| Action | Cluster onboarding (Part 1) | Tenant onboarding (Part 2) |
|--------|-----------------------------|----------------------------|
| OpenBao | Create `auth/cluster-<name>` mount + `tenant` role | Add child ns `<cluster>-<tenant>` + seed encryption key |
| Temporal | Append issuer `JWKS_URI` to `jwksUris` | Create Temporal namespace `<slug>` |
| claim-mapper | Add `PLATFORM_SA_MAPPINGS` for non-convention SAs | Name SA `tenant-<slug>-temporal` (free grant) |
| Client cluster | Install vault-agent injector | Deploy temporal-om-worker |
| Frequency | Once per cluster | Once per tenant |
