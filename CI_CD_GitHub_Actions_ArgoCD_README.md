# GitHub Actions CI/CD Pipeline for Spring Boot Kubernetes Project

This project implements a CI/CD pipeline using **GitHub Actions, Maven, Docker, Docker Hub, Trivy, Kubernetes manifests, and Argo CD**.

The pipeline is triggered whenever code is pushed to the `main` branch.

---

# CI/CD Architecture

```text
Developer
    |
    | git push
    ▼
GitHub Repository
    |
    | push to main
    ▼
GitHub Actions
    |
    ├──────────────────────────────┐
    │                              │
    ▼                              │
Build Job                          │
├── Checkout source code           │
├── Setup Java 8                   │
├── Start MySQL service            │
├── Maven build                    │
└── Upload JAR artifact            │
                                   │
                                   ▼
                              Docker Job
                              ├── Checkout code
                              ├── Download JAR
                              ├── Login to Docker Hub
                              ├── Build Docker image
                              ├── Trivy security scan
                              └── Push image to Docker Hub
                                   |
                                   ▼
                              Docker Hub
                                   |
                                   ▼
                         Update Manifest Job
                         ├── Checkout repository
                         ├── Update image tag
                         ├── Commit app.yaml
                         └── Push changes to Git
                                   |
                                   ▼
                              Argo CD
                                   |
                                   | Detects Git change
                                   ▼
                              Kubernetes
                                   |
                                   ▼
                           New Application Pod
```

---

# 1. Pipeline Trigger

The workflow is triggered by:

```yaml
on:
  push:
    branches:
      - main
```

This means whenever code is pushed to the `main` branch, GitHub Actions starts the pipeline.

Example:

```bash
git add .
git commit -m "Update application"
git push origin main
```

This triggers the workflow automatically.

---

# 2. GitHub Actions Permissions

The workflow contains:

```yaml
permissions:
  id-token: write
  contents: write
```

### id-token: write

This permission allows GitHub Actions to request an OIDC identity token.

It is useful when GitHub Actions needs to authenticate with cloud providers such as AWS without storing long-lived cloud credentials.

### contents: write

This allows GitHub Actions to push changes back to the GitHub repository.

It is required by the `update-manifest` job because that job modifies and commits:

```text
k8s/manifest/app.yaml
```

---

# 3. Build Job

The first job is:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
```

This job runs on a GitHub-hosted Ubuntu runner.

The purpose of this job is to:

1. Checkout source code
2. Set up Java
3. Start MySQL
4. Build the Spring Boot application
5. Upload the generated JAR

---

# 4. MySQL Service Container

The build job starts a temporary MySQL container:

```yaml
services:
  mysql:
    image: mysql:8.0
```

The database is configured with:

```yaml
MYSQL_ROOT_PASSWORD: root
MYSQL_DATABASE: vetapp
```

The MySQL container is exposed on:

```text
3306
```

A health check is also configured.

This allows the CI environment to have a MySQL database available while the application is being built/tested.

---

# 5. Checkout Source Code

The workflow uses:

```yaml
- name: copy code
  uses: actions/checkout@v4
```

This checks out the latest source code from the GitHub repository onto the GitHub Actions runner.

Flow:

```text
GitHub Repository
       |
       ▼
GitHub Actions Runner
       |
       ▼
Source Code
```

---

# 6. Setup Java

The pipeline uses:

```yaml
- name: setup java
  uses: actions/setup-java@v5
  with:
    java-version: '8'
    distribution: 'temurin'
```

This installs/configures:

```text
Java 8
Eclipse Temurin
```

on the GitHub Actions runner.

---

# 7. Build Spring Boot Application

The application is built using:

```bash
mvn clean package -DskipTests
```

Maven:

```text
Clean
  ↓
Compile
  ↓
Package
  ↓
Spring Boot JAR
```

The generated JAR is typically created under:

```text
target/
```

For example:

```text
target/spring-boot-application.jar
```

---

# 8. Upload JAR Artifact

The JAR is uploaded using:

```yaml
- name: upload artifact
  uses: actions/upload-artifact@v4
  with:
    name: spring-boot.jar
    path: target/*.jar
```

This allows the next job to download the JAR.

The flow is:

```text
Build Job
    |
    ▼
target/*.jar
    |
    ▼
GitHub Actions Artifact
    |
    ▼
Docker Job
```

---

# 9. Job Dependency

The Docker job contains:

```yaml
needs: build
```

Therefore Docker will only run after the `build` job completes successfully.

```text
build
  |
  | success
  ▼
docker
```

The condition:

```yaml
if: success()
```

also ensures that the job runs only when the previous required job succeeds.

---

# 10. Docker Job

The Docker job performs:

```text
Checkout code
      ↓
Download JAR
      ↓
Docker Hub login
      ↓
Build Docker image
      ↓
Trivy security scan
      ↓
Push Docker image
```

---

# 11. Download JAR

The Docker job downloads the artifact created by the build job:

```yaml
- name: download jar
  uses: actions/download-artifact@v4
  with:
    name: spring-boot.jar
    path: target/
```

This makes the JAR available to the Docker build.

---

# 12. Docker Hub Authentication

The workflow uses:

```yaml
- name: dockerHub Login
  uses: docker/login-action@v3
```

Credentials are stored as GitHub Secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

The credentials are not hard-coded in the workflow.

---

# 13. Docker Image Build

The Docker image is built using:

```bash
docker build \
  -t ${{ secrets.DOCKERHUB_USERNAME }}/springboot-kubernetes-project:${{ github.run_number }} .
```

The image tag uses:

```text
github.run_number
```

For example:

```text
springboot-kubernetes-project:25
```

The next pipeline run could produce:

```text
springboot-kubernetes-project:26
```

This provides a unique image tag for each workflow run.

---

# 14. Trivy Security Scan

Before pushing the image, the pipeline performs a vulnerability scan using Trivy:

```yaml
- name: Trivy image scan
  uses: aquasecurity/trivy-action@master
```

It scans:

```text
OS packages
Application libraries
```

using:

```yaml
vuln-type: 'os,library'
```

Unfixed vulnerabilities are ignored:

```yaml
ignore-unfixed: true
```

The current configuration uses:

```yaml
exit-code: '0'
```

This means the scan does **not fail the pipeline even when vulnerabilities are found**.

The scan currently acts primarily as a security visibility/checking step.

---

# 15. Push Docker Image

After the image is built and scanned, it is pushed to Docker Hub:

```bash
docker push ${{ secrets.DOCKERHUB_USERNAME }}/springboot-kubernetes-project:${{ github.run_number }}
```

Example:

```text
Docker Hub
└── springboot-kubernetes-project
    ├── 21
    ├── 22
    ├── 23
    ├── 24
    └── 25
```

Each successful pipeline run creates a new image tag.

---

# 16. Update Manifest Job

The final GitHub Actions job is:

```yaml
update-manifest:
  needs: docker
```

This job runs only after the Docker job succeeds.

Its purpose is to update the Kubernetes Deployment manifest with the newly created Docker image.

---

# 17. Checkout Repository

The job first checks out the repository:

```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

This gives the runner access to:

```text
k8s/manifest/app.yaml
```

---

# 18. Update Kubernetes Image

The pipeline uses:

```bash
sed -i "s|image: .*|image: ${{ secrets.DOCKERHUB_USERNAME }}/springboot-kubernetes-project:${{ github.run_number }}|" k8s/manifest/app.yaml
```

Suppose the old manifest contains:

```yaml
image: username/springboot-kubernetes-project:24
```

After the new pipeline run:

```yaml
image: username/springboot-kubernetes-project:25
```

The Kubernetes manifest now points to the newly built Docker image.

---

# 19. Commit Manifest Change

GitHub Actions configures Git:

```bash
git config --global user.name "github-actions"
git config --global user.email "github-actions@github.com"
```

Then:

```bash
git add k8s/manifest/app.yaml
```

and:

```bash
git commit -m "Update image to build ${{ github.run_number }} [skip ci]"
```

Finally:

```bash
git push
```

pushes the updated manifest back to GitHub.

---

# 20. Why `[skip ci]` Is Used

The commit message contains:

```text
[skip ci]
```

This prevents the manifest update from unnecessarily triggering the same CI workflow again.

Without it, the flow could become:

```text
Code Push
   ↓
GitHub Actions
   ↓
Update app.yaml
   ↓
Git Push
   ↓
GitHub Actions
   ↓
Update app.yaml
   ↓
Git Push
   ↓
...
```

Using:

```text
[skip ci]
```

prevents this unwanted CI trigger.

---

# 21. Argo CD Deployment

GitHub Actions does **not directly deploy the application to Kubernetes** in this pipeline.

Instead, GitHub Actions updates:

```text
k8s/manifest/app.yaml
```

and pushes that change to Git.

Argo CD watches the Git repository.

The flow is:

```text
GitHub Actions
      |
      | updates image tag
      ▼
Git Repository
      |
      | detects manifest change
      ▼
Argo CD
      |
      | Sync
      ▼
Kubernetes
      |
      ▼
New Docker Image
      |
      ▼
New Application Pod
```

This is a **GitOps-based deployment approach**.

---

# 22. Complete End-to-End Flow

```text
1. Developer writes code
          ↓
2. git push origin main
          ↓
3. GitHub Actions starts
          ↓
4. Build Job
   ├── Checkout code
   ├── Setup Java 8
   ├── Start MySQL
   ├── Maven package
   └── Upload JAR
          ↓
5. Docker Job
   ├── Download JAR
   ├── Docker Hub login
   ├── Build image
   ├── Trivy scan
   └── Push image
          ↓
6. Update Manifest Job
   ├── Update image tag
   ├── Commit app.yaml
   └── Push to Git
          ↓
7. Argo CD detects Git change
          ↓
8. Argo CD syncs Kubernetes
          ↓
9. Kubernetes performs deployment
          ↓
10. New application version is running
```

---

# 23. GitHub Secrets Used

The workflow references:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

These should be configured in:

```text
GitHub Repository
→ Settings
→ Secrets and variables
→ Actions
```

Never hard-code Docker Hub credentials directly in the workflow.

---
# 24. CI/CD Summary

```text
Git Push
   ↓
GitHub Actions
   ↓
Maven Build
   ↓
JAR Artifact
   ↓
Docker Build
   ↓
Trivy Scan
   ↓
Docker Hub
   ↓
Update Kubernetes Manifest
   ↓
Git Push
   ↓
Argo CD
   ↓
Kubernetes
   ↓
Application Deployment
```

## Result

The complete process is automated from **source-code push to Kubernetes deployment**, while Argo CD maintains Kubernetes deployment through the Git repository as the source of truth.
