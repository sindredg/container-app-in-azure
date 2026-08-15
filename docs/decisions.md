# Decision Log

This log records the main architecture and delivery decisions.

| Decision | Status | Reason |
|---|---|---|
| Use Azure Container Apps | Accepted | Provides managed ingress, scaling, revisions, and probes without operating Kubernetes. |
| Use separate web and API Container Apps | Accepted | Each service can deploy and scale independently. |
| Expose only the web app publicly | Accepted | Keeps the future API behind internal ingress. |
| Use one shared Container Apps environment | Accepted | Provides shared networking, logging, and service discovery. |
| Store images in private ACR | Accepted | Keeps application artifacts under controlled access. |
| Pull images with managed identity | Accepted | Avoids registry passwords in configuration and state. |
| Keep runtime access read-only | Accepted | The application can pull images but cannot publish them. |
| Use immutable image tags | Accepted | Each deployment points to a known artifact and rollback target. |
| Build Azure images for `linux/amd64` | Accepted | Matches the selected Azure runtime architecture. |
| Use port `8080` and `/health` | Accepted | Keeps Docker, Nginx, ingress, and probes aligned. |
| Start with zero to one replica | Accepted | Keeps the first deployment simple and cost-aware. |
| Use single revision mode first | Accepted | Sends traffic to one active release while revision behavior is learned. |
| Store Terraform state in Azure Blob Storage | Accepted | Enables remote state, locking, versioning, and recovery controls. |
| Add GitHub Actions after the manual workflow | Deferred | Manual execution builds understanding before automation. |
| Use FastAPI for the internal API | Accepted | Small image, JSON by default, and a published schema for the service contract. |
| Reach the API through the web container's origin | Accepted | The browser never learns the internal hostname, no cross-origin request is made, and the call stays inside the existing Content Security Policy. |
| Remove the client address at the proxy | Accepted | The API is told the truncated network instead, which correlates a request across both tiers without carrying an address. |
| Disable the interactive API documentation | Accepted | Its assets load from a public CDN, so serving it would mean weakening the Content Security Policy. |
| Inject the API address at container start | Accepted | Keeps one immutable image usable in every environment instead of one build per address. |
| Run the API container as a non-root user | Accepted | Matches the unprivileged user the Nginx base image already provides for the web container. |
| Log the request rather than the caller in the API | Accepted | Extends the phase 8 privacy stance to the second tier, where no address is needed at all. |

Future decisions will cover automated delivery identity and per-app pull identities.
