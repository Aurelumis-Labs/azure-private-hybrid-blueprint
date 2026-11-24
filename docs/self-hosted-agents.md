# Self-hosted agents

With public access disabled, a Microsoft-hosted agent cannot reach the app or Key Vault. Run deployments from agents inside the virtual network.

- Place agents in `snet-agents` (created by `modules/network.bicep`).
- Register them in an Azure DevOps pool, for example `pool-contoso-selfhosted`, and add a demand or capability such as `TargetEnvironment=PROD` so jobs only land on agents in the right network.
- Give the agent identity only the roles it needs on the target resource group.
- Keep the agent image patched and ephemeral where possible (scale set agents), and never store credentials on the agent.

Compatible pipeline pattern: see the `azure-devops-pipeline-templates` repository (production stage with a pool and a demand).
