# ADR-0007: Private by default for Azure workloads

- **Status:** Proposed
- **Date:** 2026-11-23
- **Decision owner:** Avinash Padaki
- **Jira:** KAN-82
- **Repo / PR:** azure-private-hybrid-blueprint (PR pending)

## Context

Workloads for regulated or customer-controlled environments cannot assume public endpoints. Reaching a service should require network presence, not only a credential.

## Decision

1. Every data-plane service in the blueprint (web app and Key Vault) has `publicNetworkAccess: Disabled` and is reached through a private endpoint with a linked private DNS zone.
2. The app reaches Key Vault over a VNet integration subnet using a user-assigned managed identity and Azure RBAC (Key Vault Secrets User). No keys, passwords or connection strings are stored in app settings.
3. Deployments and operators run from inside the network using self-hosted agents in a dedicated subnet.

## Alternatives considered

- IP allow-lists on public endpoints: simple, but the endpoint stays internet-reachable.
- Service endpoints: private routing, but the service keeps a public address.
- Public endpoints with Entra ID authentication only: lowest effort, but exposes the service to internet scanning and credential attacks.

## Consequences

**Benefits:** A reduced attack surface; secrets are never stored in configuration; access depends on both network position and identity.

**Costs and risks:** Deployments and debugging need private connectivity (self-hosted agents, jump host or VPN). DNS becomes part of the design: an unlinked private DNS zone silently falls back to public addresses. Premium-tier App Service plans cost more.

## Non-goals

Hub-and-spoke networking, firewalls, on-premises connectivity (VPN or ExpressRoute), multi-region.

## Validation criteria

`az bicep build` passes. In a scratch resource group, `what-if` shows no public network access on the site or vault, private endpoints resolve to private addresses from inside the network, and the app reads a Key Vault secret through its managed identity.
