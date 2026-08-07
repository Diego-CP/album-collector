# Album Collector
## Demo Video
See a demo video here.
## Rationale
The inspiration for this project came from the following YouTube video, calculating the monetary cost difference when completing the 2026 album with larger groups of people: https://www.youtube.com/watch?v=_NkHmc3RAS8

Thus, Album Collector aims to facilitate trading in groups by automatically calculating available trades between group members.

This is both a useful tool and a learning project aiming to put in practice AWS, Terraform, Kubernetes and CI/CD knowledge. Thus, the infrastructure was designed for cheap operation and to be constantly torn down and brought back up.

## Containerization
### [Dockerfile](Dockerfile)
Builds the app image and bundles `dbmate` for the migration job.

Key points:
* `dumb-init` is used to run as PID 1 and forward `SIGTERM` signals to Node, as well as reap zombie processes. Since PID 1 doesn't get the kernel's default signal handlers, running Node in PID 1 would prevent graceful shutdowns from `SIGTERM` signals.
* `dbmate` is used for database migrations because it is lightweight, idempotent, language-agnostic and automatically records applied migrations in `schema_migrations`. However, there's no schema diffing. The arm64 version is used to match the Graviton instances (see [here](./infra/eks/variables.tf)) and installed as a standalone binary.
* `NODE_ENV=production` skips `devDependencies` and installs only `dependencies`.
* `COPY package*.json` happens before `COPY . .`, so dependencies are only re-installed when `package*.json` change, since Docker caches layers top-down.
* Image default `NODE_ENV=production`. This forces `Secure` cookies in the app (see [here](./app/server/routes/authentication.js)).
* `HEALTHCHECK` is commented out because it is ignored by k8s, which uses its own probes.

### [Docker Compose](docker-compose.yml)
Runs the application and database containers.

Key points:
* `environment` overrides `env_file`. `DB_HOST` and `DATABASE_URL` override the `.env` values because, inside the compose network, containers resolve each other by service name. Using `localhost` would mean the `app` container itself in the compose network. This way, `.env` with `localhost` can still be used for my local environment.
* `depends_on` makes the app wait for a DB that's actually accepting queries. This is compose-only, as k8s has no equivalent.
* `NODE_ENV: development` for local dev using HTTP (see [here](./app/server/routes/authentication.js)).
* Volume `db_data` persists across `up`/`down`.

## AWS Infrastructure
The infrastructure is fully Terraform-defined and divided into the following stacks (found in `/infra`):
#### [Bootstrap](./infra/bootstrap)
Creates an S3 bucket to store remote Terraform state. Encrypted, with versioning enabled and `prevent_destroy`. Requires Terraform 1.10+ for S3-native state locking.

Key points:
* The remote state bucket name is environment-specific and needs to be added manually to all other stacks. Add your specific bucket to each stack's `backend.tf`.
#### [Network](./infra/network)
Creates subnets, the IGW, NAT Gateways and Route Tables.

Key points:
* VPC has a `/16` CIDR range, broken down into `/20` subnets. This allows for 16 subnets with 65,531 usable IPs, although only 4 `/20` subnets are used. Deliberately spacious to allow for future scaling.
* NAT can be enabled/disabled with `-var enable_nat=true`. This is useful for shutting down NAT when not in use, as it's one of the biggest cost contributors.
* Public subnets are tagged with `"kubernetes.io/role/elb" = "1"` and private subnets with `"kubernetes.io/role/internal-elb" = "1"` for the Load Balancer Controller's subnet autodiscovery (see [here](./infra/addons/load_balancer_controller.tf)). However, there is no internal LB, it's just future-proofing.
#### [ECR](./infra/ecr)
Creates encrypted ECR repository for storing container images.

Key points:
* Images are scanned on push.
* Image tags are immutable.
* Lifecycle policy expires untagged images after 14 days and only keeps the most recent 10 images.
#### [Database](./infra/database)
Creates an Aurora Serverless v2 database with encryption and scale-to-zero, together with a dedicated Security Group. Because the database can scale to zero, it is meant to be persistent across teardowns. Thus, these security measures are used:
```
backup_retention_period = 7
skip_final_snapshot = false
deletion_protection = true
```

Key points:
* An RDS-managed master password is used to prevent it from showing up in TF or git state.
* A Secrets Manager secret is created to store the Cognito client secret. Its value is environment-specific and assigned manually to prevent it from showing up in TF or git state. Set it in your own AWS environment.
* The Security Group allows ingress from anywhere in the VPC. This was a deliberate choice for the bastion first, then because the EKS stack is meant to be torn down. So, scoping ingress to the EKS node's Security Group only would couple a persistent resource to an ephemeral one.
#### [Bastion](./infra/bastion)
Creates a single throwaway EC2 instance, plus an IAM role granting SSM Session Manager access and a dedicated Security Group. Used before the EKS stack existed to reach the private Aurora database from a laptop via SSM port-forwarding in order to validate connectivity and run the initial migrations.

Key points:
* The Security Group has no inbound rules, as access is outbound-only via the SSM agent.
#### [EKS](./infra/eks)
Creates an EKS cluster on node groups using Graviton EKS-optimized Amazon Linux 2023 Spot instances.

Key points:
* Node groups were used over Fargate for the AMI and autoscaling learning opportunity.
* For the instances used: Spot for cost, M-family for cost, Graviton for price-to-performance.
* Instance type is diversified over various `m*g.medium` instances in order to keep a consistent shape for the Cluster Autoscaler (see [this section](#cluster-autoscaler)): 1-vCPU / 4 GB arm64 mediums.
* Prefix delegation is used so each ENI slot yields a `/28` (16 IPs) instead of a single IP, lifting a node's pod ceiling from the ENI-limited default (as low as 8 on `m*g.medium` instances) to ~100-110. Nodes compute their `max-pods` at boot based on how the CNI is configured, so `before_compute = true` makes sure the CNI is in prefix mode before nodes join. `WARM_PREFIX_TARGET = "1"` will keep one spare `/28` prefix allocated and ready per node, ahead of demand, aiming to smooth pod launches without hoarding subnet IP space.
* IRSA is used instead of Pod Identity. This was a development convenience, as it lined up with followed guides. However, using Pod Identity is a future improvement (see the [Future Improvements](#future-improvements) section).
* Secret envelope-encryption with a customer-managed KMS key is intentionally not enabled: secrets live in Secrets Manager and ESO syncs them in at runtime. The only in-cluster Secret is the ephemeral copy ESO creates.
#### [Addons](./infra/addons)
##### ESO
External Secrets Operator (ESO) is used to continuously sync the DB password and Cognito client secret from Secrets Manager into a native k8s Secret
(`app-secrets`) that the app consumes via `envFrom` (see [here](./k8s/app/deployment.yaml)). This replaces manually recreating the Secret on every cluster rebuild and keeps secret values out of TF or git state.

The stack installs ESO from an official Helm chart, uses the `iam-role-for-service-accounts-eks` module to create an IRSA role with a permissions policy scoped to exactly the two secret ARNs and a trust relationship allowing only the `external-secrets` service account to assume it. Finally, it creates and annotates that `external-secrets` ESO service account.
##### Load Balancer Controller
The Load Balancer Controller is used so that the ALB can be provisioned from an Ingress. See [this section](#ingress) for more information. An Ingress-provisioned ALB is required to keep the ALB's target group in sync with live pods, as opposed to constantly updating a Terraform-provisioned ALB.

Uses the same `iam-role-for-service-accounts-eks` module and an official Helm chart to repeat the IRSA pattern from ESO, allowing the Controller's pod to perform AWS API calls scoped to its ALB.
##### External DNS
External DNS is used to automatically manage Route 53 records to match the current ALB, since the entire EKS stack is constantly destroyed and rebuilt. It reads `host` from [Ingress](#ingress).

Uses the same `iam-role-for-service-accounts-eks` module and an official Helm chart to repeat the IRSA pattern from ESO, allowing the ExternalDNS pod to perform AWS API calls scoped to the project's Route 53 hosted zone.

Key points:
* Ownership is tracked via companion TXT records. A stable `txtOwnerId` (project name) lets a rebuilt ExternalDNS recognize and manage records from the previous cluster instead of orphaning them.
* ExternalDNS won't touch a record it doesn't own, so a record orphaned by an out-of-order teardown won't self-heal. The correct teardown order is: delete Ingress, wait for ALB + DNS removal, then destroy.
##### Metrics Server
Metrics Server scrapes each node's kubelet over HTTPS to collect CPU/memory. Used by HPA for pod scaling (see [here](./k8s/app/hpa.yaml)).

Key points:
* `--kubelet-insecure-tls` is used for now, but enabling kubelet serving certificate signing is a [future improvement](#future-improvements).
##### Cluster Autoscaler
Scales at the node level based on requests: when pods are stuck `Pending` because no existing node can satisfy their resource requests, CA adds nodes. When nodes sit underused, it removes them.

Uses the same `iam-role-for-service-accounts-eks` module and an official Helm chart to repeat the IRSA pattern from ESO, allowing the Cluster Autoscaler pod to perform AWS API calls scoped to the Auto-Scaling Groups tagged for this cluster.

Key points:
* Cluster Autoscaler is why all spot instances must share a shape: CA models each node group as a _single_ representative node "template" and simulates whether a `Pending` pod would fit on a new node from that group. A mixed-shape group makes that _one_ template inaccurate: CA may expect capacity a smaller instance won't have, or decide a pod can never fit on an instance that is larger than it expects. Same-shape instance types keep the simulation accurate.
* CA respects the ASG's min/max, so it scales only within the node group's configured bounds.
* CA with the HPA: HPA changes pod count, CA changes node count. HPA wants more pods -> no room -> CA adds a node -> pods schedule.
#### [DNS](./infra/dns)
Creates the Route 53 hosted zone for the domain (delegated from the registrar) and issues a DNS-validated ACM certificate for it, used for TLS communication on the ALB.
#### [CI/CD](./infra/cicd)
Registers GitHub Actions as a trusted OIDC identity provider, and creates the IAM role it assumes for CI/CD, scoped to the ECR repo and EKS cluster.

Key points:
* This replaces long-lived AWS access keys stored in GitHub. Instead: GitHub mints a JWT -> AWS validates the JWT came from a trusted provider with the correct `aud` and `sub` -> AWS returns temporary credentials.
* Only workflow runs from this repo's `main` branch may assume the role.
* This grants AWS API permissions only. In-cluster `kubectl` access is granted separately, in the EKS stack (see [here](./infra/eks/eks.tf)).

## Kubernetes
Defined in `/k8s`, divided into the following manifests:

In `/app`: 
##### [Configmap](./k8s/app/configmap.yaml)
Defines `NODE_ENV`, `PORT`, `AWS_REGION`, DB and Cognito _non-sensitive_ configurations. These are then injected as environment variables via `envFrom` (see the [deployment](./k8s/app/deployment.yaml)).

Key points:
* Using `NODE_ENV: "production"` mirrors the image default (from the [Dockerfile](./Dockerfile)) and  forces `Secure` cookies in the app (see [here](./app/server/routes/authentication.js)).
* The Cognito infrastructure was created during development, so it is not defined in Terraform. Defining Cognito infrastructure is a future improvement (see the [Future Improvements](#future-improvements) section).
##### [Deployment](./k8s/app/deployment.yaml)
Defines the deployment, including: ownership of pods, pod-level security context, and the app container's configuration, including: where to pull environment variables from, the resources each pod should consume, container-level security context and startup/liveness/readiness probes.

Key points:
* `seccompProfile: { type: RuntimeDefault }` Uses a seccomp (secure computing mode) profile in order to restrict the system calls the container may make, using the container runtime's (containerd on EKS) default profile.
* The deployment meets all pod and container-level Restricted controls defined in the [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted). This is enforced by Pod Security Admission, opted into in the [namespace manifest](./k8s/cluster/namespace.yaml).
##### [HPA](./k8s/app/hpa.yaml)
Defines the Horizontal Pod Autoscaler ownership, min/max replicas, metric and target. It owns the deployment's replica count.

Key points:
* The target `averageUtilization: 80` is 80% of each pod's CPU request. With a `100m` request defined in the [deployment](./k8s/app/deployment.yaml), the HPA scales out when average CPU exceeds `80m` per pod.
* Uses default scaling behavior:
    * Scaling up: stabilization defaults to 0s, so, whenever the controller detects that metrics have exceeded the threshold. The controller polls metrics every 15s by default.
    * Scaling down: 300s stabilization window.
##### [Ingress](./k8s/app/ingress.yaml)
A single Ingress that two controllers consume: the Load Balancer Controller reads it to provision the ALB (public, pod-IP targets, HTTP to HTTPS redirect with the ACM certificate, and a `/health/ready` health-check path), and ExternalDNS reads its `host` to create the Route 53 alias record pointing `album-collector.online` at that ALB.

Key points:
* The certificate ARN and `host` are environment-specific values - set them to your own ACM cert and domain.
* `host` is the routing rule and hostname ExternalDNS uses.
##### [Service](./k8s/app/service.yaml)
Service selects all pods carrying the `app: album-collector` label and exposes their IPs as the Service's endpoints. The ALB controller reads those endpoints to continuously register the pod IPs into the ALB's target group.

Key points:
* The Service is not in the path for public traffic. Because the [Ingress](./k8s/app/ingress.yaml) uses `target-type: ip`, the ALB sends requests straight to pod IPs. With `target-type: instance` the ALB would hit node ports and the Service/kube-proxy would do the final hop to a pod.
* The Service also has a stable `ClusterIP` that any in-cluster client could use to reach these `app: album-collector` pods, load-balanced by Service/kube-proxy. The app has no internal callers, so that path is currently unused.

In `/cluster`: 
##### [Cluster Secret Store](./k8s/cluster/clustersecretstore.yaml)
The Store defines where to go to retrieve a secret (AWS Secrets Manager) and how to authenticate: use the ESO service account.

The general flow to retrieve a secret is:
1. ESO needs to read a secret, so it looks at this manifest. The Store says it should authenticate as the `external-secrets` service account.
    1. That service account is annotated with the IRSA role ARN (see [here](./infra/addons/eso.tf)). The role's trust policy allows this specific service account to assume it (the `sub` check), and its permissions policy scopes it to the two secret ARNs.
    2. Kubernetes projects a signed ServiceAccount JWT (usable as an OIDC token) into ESO's pod.
2. ESO uses the AWS SDK to exchange the JWT with STS for temporary AWS credentials. STS validates the JWT signature against the registered OIDC provider, plus the IRSA role's trust policy `sub` check.
3. ESO uses those credentials to call `secretsmanager:GetSecretValue`.

The IRSA authentication process is explained in a more general context in the [Future Improvements](#future-improvements) section.
##### [External Secret](./k8s/cluster/externalsecret.yaml)
Defines which secrets to pull from Secrets Manager and the native K8s Secret to write them into.

Key points:
* Flow: the External Secret triggers a sync -> ESO reads its `secretStoreRef` and resolves the referenced `ClusterSecretStore` -> authenticates/connects via that Store -> fetches the secrets named in External Secret's `remoteRef` -> writes them into the target Secret (`app-secrets`).
* `refreshInterval: 1h` will re-read Secrets Manager hourly. However, it refreshes the Secret object, not running pods (environment variables are read at container start).
##### [Namespace](./k8s/cluster/namespace.yaml)
Simply defines the namespace and enforces the Restricted controls defined in the [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted).
##### Standalone: [Migrate Job](./k8s/migrate-job.yaml)
The Migrate Job creates a single-run pod that applies any pending migrations to the Aurora database.

Key points:
* This is run as part of the CI/CD pipeline, before the app is rolled out.
* Migrations run in-cluster because Aurora has no public endpoint. A pod is the only thing that can reach it.
* The Job uses the namespace's `default` service account rather than a dedicated one because it doesn't need RBAC permissions (it makes no k8s API calls). It only connects to Aurora over TCP, reading  `app-secrets` via `envFrom` - that's just the kubelet mounting the Secret into the pod, not an API call by the service account.
* The job's manifest meets all pod and container-level Restricted controls defined in the [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/#restricted). This is enforced by Pod Security Admission, opted into in the [namespace manifest](./k8s/cluster/namespace.yaml).

## Future Improvements
In-app: 
* Add player images and progress bar to Collection UI.
* 4-way trades.
* Refactor to allow for multiple albums or collections.

Infrastructure:
* Use Pod Identity instead of IRSA. 
    * With IRSA: the EKS TF module creates an OIDC provider in IAM by default. A service account is annotated with a role ARN; pods running as that service account get a signed OIDC token projected into them. The pod presents that token to STS to receive temporary credentials. STS validates both the token's signature against the registered OIDC provider _and_ the target's role trust policy `sub` condition (confirming the request comes from the specific `namespace:serviceaccount` the trust policy is scoped to).
    * With Pod Identity: an agent runs on each node, calling STS on the pod's behalf and handing back the temporary credentials. A Pod Identity Association maps a `namespace:serviceaccount` to an IAM role ARN. This makes it so the IAM role's trust policy is a fixed boilerplate that trusts the `pods.eks.amazonaws.com` service principal: "service account X in namespace Y -> role Z". There's no OIDC provider and no per-cluster `sub` condition, so it's reusable across clusters.
* Enable kubelet serving certificate signing (from [here](./infra/addons/metrics_server.tf)) in order for Metrics Server to collect data from kubelets using TLS. Accepted for now because the scrape happens over the internal cluster network, not anything internet-facing.

    The kubelet's serving certificate is, by default, self-signed, so it's not trusted by Metrics Server. Kubernetes won't auto-approve _serving_ Certificate Signing Requests (CSRs) for SAN-spoofing reasons: a node can request a signed certificate for _any_ SAN (Subject Alternative Name - the field in a certificate that defines who the cert is valid for), potentially allowing it to obtain a signed certificate for _any_ identity and use that validly-signed cert to impersonate the node and intercept traffic meant for it. Therefore, the CSR approver used must also check that the SANs specified in the CSR correspond to the node that submitted it.

    So, proper verification needs:
    * `serverTLSBootstrap` for kubelet to actually submit CSRs.
    * A validating CSR approver. Standard is `kubelet-csr-approver`.
* Use DB proxy.
* Use CloudFront (once there is static content to serve in the app).
* Define Cognito infrastructure through Terraform.
* Delegate recalculation of trades to an asynchronous job using SQS and Lambda.

## References
The basis of this project came from this repository: https://github.com/acemilyalcin/sample-node-project

Most of this project was developed using AI assistance. The documentation was created with no AI assistance.
