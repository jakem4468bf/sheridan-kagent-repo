# 🎓 Sheridan College - AI Agents & Kubernetes Lab

**Course:** AI & Software Defined Networking  
**Instructor:** Professor Sebastian Maniak  
**Lab Assignment:** Building AI-Powered Kubernetes Agents with Kagent

---

## 📋 Assignment Overview

In this lab, you will deploy and configure **Kagent** - an open-source framework for building AI agents that can interact with Kubernetes clusters and development tools. You'll create an AI-powered "Team Lead Agent" that can automatically diagnose Kubernetes issues and document them in GitHub.

**Learning Objectives:**
- Understand how AI agents interact with cloud-native infrastructure
- Deploy and configure Kubernetes clusters using Kind
- Work with Helm charts and Kubernetes custom resources
- Integrate AI (OpenAI) with infrastructure automation
- Practice GitOps workflows and documentation standards

---

## 🛠️ Prerequisites

Before starting this lab, ensure you have:

- [ ] **Docker Desktop** installed and running
- [ ] **kind** (Kubernetes in Docker) - [Install Guide](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [ ] **kubectl** - [Install Guide](https://kubernetes.io/docs/tasks/tools/)
- [ ] **Helm** v3.x - [Install Guide](https://helm.sh/docs/intro/install/)
- [ ] **Git** installed
- [ ] **GitHub account** with a Personal Access Token
- [ ] **OpenAI API key** (provided by instructor or use free tier)

---

## 📚 Part 1: Environment Setup (20 points)

### Step 1.1: Fork and Clone This Repository

1. Fork this repository to your GitHub account
2. Clone your fork:
```bash
git clone https://github.com/YOUR_USERNAME/sheridan-kagent-repo.git
cd sheridan-kagent-repo
```

### Step 1.2: Create Kubernetes Cluster

```bash
# Create a Kind cluster with the provided configuration
kind create cluster --name sheridan-kagent --config kind-config.yaml

# Verify cluster is ready
kubectl cluster-info
kubectl get nodes

# Wait for system components
kubectl -n kube-system rollout status deploy/coredns
```

**📸 Screenshot Required:** Show output of `kubectl get nodes` with your cluster running.

### Step 1.3: Install Kagent

```bash
# Set your OpenAI API key
export OPENAI_API_KEY="your-key-here"

# Install Kagent CRDs
helm install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
    --namespace kagent --create-namespace

# Install Kagent
helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --namespace kagent \
    --set providers.default=openAI \
    --set providers.openAI.apiKey=$OPENAI_API_KEY

# Wait for Kagent to be ready
kubectl wait --for=condition=ready pod -l app=kagent -n kagent --timeout=300s
```

**📸 Screenshot Required:** Show output of `kubectl get pods -n kagent`

---

## 🔧 Part 2: Configure GitHub Integration (20 points)

### Step 2.1: Create GitHub Personal Access Token

1. Go to GitHub → Settings → Developer Settings → Personal Access Tokens → Tokens (classic)
2. Generate new token with scopes: `repo`, `read:org`
3. Save the token securely

### Step 2.2: Update Agent Configurations

Edit the agent YAML files in `agents/` directory:

**In `agents/github-issues-agent.yaml`, `agents/github-pr-agent.yaml`, and `agents/teamlead-agent.yaml`:**

Find and replace:
```
sebbycorp/ai-kagent-demo
```
With:
```
YOUR_GITHUB_USERNAME/sheridan-kagent-repo
```

### Step 2.3: Deploy GitHub MCP Server

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="your-token-here"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: github-pat
  namespace: kagent
type: Opaque
stringData:
  GITHUB_PERSONAL_ACCESS_TOKEN: $GITHUB_PERSONAL_ACCESS_TOKEN
---
apiVersion: kagent.dev/v1alpha2
kind: RemoteMCPServer
metadata:
  name: github-mcp-remote
  namespace: kagent
spec:
  description: GitHub Copilot MCP Server
  url: https://api.githubcopilot.com/mcp/
  protocol: STREAMABLE_HTTP
  headersFrom:
    - name: Authorization
      valueFrom:
        type: Secret
        name: github-pat
        key: GITHUB_PERSONAL_ACCESS_TOKEN
  timeout: 5s
  terminateOnClose: true
EOF
```

### Step 2.4: Deploy Agents

```bash
kubectl apply -f agents/

# Verify agents are deployed
kubectl get agents -n kagent
kubectl get remotemcpserver -n kagent
```

**📸 Screenshot Required:** Show output of `kubectl get agents -n kagent`

---

## 🚀 Part 3: Run the Demo (30 points)

### Step 3.1: Start the Kagent UI

```bash
kubectl port-forward svc/kagent-ui -n kagent 8080:8080
```

Open your browser: http://localhost:8080

### Step 3.2: Deploy a Broken Pod

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: broken-nginx
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:latesttttt
    ports:
    - containerPort: 80
EOF
```

### Step 3.3: Use the AI Agent to Diagnose

1. In the Kagent UI, select **team-lead-agent**
2. Enter this prompt:
```
Why is the broken-nginx Pod failing in my default namespace?
If there is an issue, create a GitHub issue with all details including logs, events, and proposed fix.
```

3. Watch the agent:
   - Investigate the pod using kubectl commands
   - Identify the root cause (typo in image tag)
   - Create a comprehensive GitHub issue in your repo

**📸 Screenshot Required:** 
- Screenshot of the Kagent UI showing the agent's response
- Screenshot of the GitHub issue created by the agent

### Step 3.4: Additional Prompts to Try

Try these additional prompts and document the results:

```
Check all pods across all namespaces and report any issues
```

```
Create a PR to fix the broken-nginx pod with the correct image tag
```

```
List all open GitHub issues in the repository
```

---

## 📝 Part 4: Written Report (30 points)

Create a file called `REPORT.md` in your repository with the following sections:

### 4.1 Executive Summary (5 points)
- What is Kagent and what problem does it solve?
- How does it fit into modern DevOps/SRE workflows?

### 4.2 Technical Architecture (10 points)
- Explain the architecture diagram below
- How do the agents communicate?
- What role does MCP (Model Context Protocol) play?

```
User → Team Lead Agent → K8s Agent (diagnose) 
                       → GitHub Issues Agent (document)
                       → GitHub PR Agent (fix)
```

### 4.3 Hands-On Experience (10 points)
- What challenges did you encounter during setup?
- How did the AI agent perform in diagnosing the issue?
- Was the GitHub issue comprehensive and accurate?
- What improvements would you suggest?

### 4.4 Real-World Applications (5 points)
- How could AI agents like this be used in enterprise environments?
- What are the security considerations?
- How does this relate to software-defined networking concepts?

---

## 📤 Submission Instructions

### Method 1: GitHub Classroom (Recommended)

1. Ensure all your work is committed to your forked repository
2. Your repository should contain:
   ```
   sheridan-kagent-repo/
   ├── README.md              # This file (unmodified)
   ├── REPORT.md              # Your written report
   ├── screenshots/           # All required screenshots
   │   ├── 01-nodes.png
   │   ├── 02-kagent-pods.png
   │   ├── 03-agents.png
   │   ├── 04-kagent-ui.png
   │   └── 05-github-issue.png
   ├── kind-config.yaml
   └── agents/
       ├── github-issues-agent.yaml  # Updated with your repo
       ├── github-pr-agent.yaml      # Updated with your repo
       └── teamlead-agent.yaml       # Updated with your repo
   ```

3. Create a **Release** in your repository:
   - Go to your repo → Releases → Create new release
   - Tag: `v1.0-submission`
   - Title: `Lab Submission - [Your Name]`
   - Description: Brief summary of your work

4. Submit the release URL to the course portal

### Method 2: Pull Request

1. Create a branch named `submission/YOUR_STUDENT_ID`
2. Add all your work to this branch
3. Create a Pull Request to the main instructor repository
4. PR Title: `[Submission] Your Name - Student ID`

---

## 🏆 Grading Rubric

| Component | Points | Criteria |
|-----------|--------|----------|
| Environment Setup | 20 | Cluster running, Kagent installed, screenshots provided |
| GitHub Integration | 20 | Agents configured correctly, GitHub integration working |
| Demo Execution | 30 | Successfully diagnosed issue, created GitHub issue |
| Written Report | 30 | Comprehensive, technical depth, real-world analysis |
| **Total** | **100** | |

**Bonus Points (+10):**
- Deploy an additional broken resource and have the agent diagnose it
- Integrate Slack notifications (see `slack/` folder)
- Create a custom agent for a specific use case

---

## 🧹 Cleanup

When you're finished:

```bash
# Delete the broken pod
kubectl delete pod broken-nginx

# Delete the Kind cluster
kind delete cluster --name sheridan-kagent

# Remove Docker resources (optional)
docker system prune -f
```

---

## 📚 Resources

- [Kagent Documentation](https://kagent.dev/docs)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Kind Documentation](https://kind.sigs.k8s.io)
- [Helm Documentation](https://helm.sh/docs)

---

## ❓ Getting Help

- **Office Hours:** Check course calendar
- **Discord:** Sheridan AI/SDN channel
- **GitHub Issues:** Create an issue in this repo with the `question` label

---

*© 2026 Sheridan College - AI & Software Defined Networking*  
*Professor Sebastian Maniak*
