# azure-private-hybrid-blueprint

A Bicep blueprint for a private-by-default Azure workload: a web app and Key Vault with public access disabled, reached through private endpoints, with a managed identity, RBAC and a subnet for self-hosted deployment agents.

> Status: reference blueprint with synthetic names. It has not been deployed or compiled in this repository's authoring environment; run `az bicep build` and `az deployment group what-if` before any real use, and review it against your own policies.

## What this demonstrates

- **Private networking:** a virtual network with app, private-endpoint and agent subnets; private endpoints for the web app and Key Vault with private DNS zones linked to the network.
- **No public data plane:** `publicNetworkAccess: Disabled` on the site and the vault; Key Vault uses `networkAcls.defaultAction: Deny`.
- **Identity over secrets:** a user-assigned managed identity reads Key Vault secrets through RBAC (Key Vault Secrets User); no credentials in app settings.
- **Hybrid-ready operations:** a dedicated agent subnet and guidance for self-hosted agents, because deployments to a private target must start from inside the network.
- **Decisions recorded:** an ADR explains the trade-offs.

## Layout

```text
main.bicep                  composes the modules
modules/
  network.bicep             VNet, subnets, NSG, private DNS zones and links
  identity.bicep            user-assigned managed identity
  keyvault.bicep            vault (RBAC, purge protection, no public access) and role assignment
  webapp.bicep              Linux plan and site (VNet integration, no public access)
  privateEndpoint.bicep     reusable private endpoint with DNS zone group
parameters/dev.bicepparam   example parameters
docs/adr/0007-private-by-default.md   private-by-default decision
docs/self-hosted-agents.md  how to deploy into the private network
```

## Deploy (after review)

```bash
az group create -n rg-contoso-dev -l canadacentral
az deployment group what-if -g rg-contoso-dev -p parameters/dev.bicepparam
az deployment group create  -g rg-contoso-dev -p parameters/dev.bicepparam
```

Run the deployment from a network with permission to create these resources. Deploying application code afterwards needs an agent inside the virtual network.

## Known limits

- Single region, single app; no firewall, hub-and-spoke or on-premises connectivity (VPN or ExpressRoute) is included.
- Private DNS covers Key Vault and App Service only; add zones for every new private endpoint.
- The NSG is minimal. Add rules to match your network standards.

## License

MIT
