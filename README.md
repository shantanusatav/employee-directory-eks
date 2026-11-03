# Employee Directory – Cloud-Native Deployment on Amazon EKS

A small Flask web application deployed to **Amazon EKS** with a full CI/CD + GitOps pipeline:

```
Developer → GitHub → GitHub Actions → Docker Image → Amazon ECR
          → Git deployment config (k8s/) → Argo CD → Amazon EKS → Running App
```

## Features
1. **Add employees** – name, department, email
2. **Search employees** by name or department
3. **Delete employees**
4. `/health` endpoint (used by Kubernetes readiness/liveness probes) and `/api/employees` JSON API

## Tech stack
| Layer | Tool |
|---|---|
| App | Python 3.12, Flask, SQLite, Gunicorn |
| Tests | pytest |
| Container | Docker |
| Registry | Amazon ECR (`employee-directory`) |
| Orchestration | Amazon EKS (`employee-cluster`, ap-south-1) |
| CI | GitHub Actions (OIDC auth, no stored AWS keys) |
| CD / GitOps | Argo CD (auto-sync, self-heal) |

## Project structure
```
app/                     Flask application + HTML template
tests/                   pytest unit tests
Dockerfile               Container image definition
k8s/                     Kubernetes Deployment + LoadBalancer Service (watched by Argo CD)
argocd/application.yaml  Argo CD Application definition
.github/workflows/       CI/CD pipeline
scripts/                 EC2 tool install, EKS cluster config, OIDC setup, cleanup
```

## Run locally
```bash
pip install -r requirements.txt
python app/app.py              # http://localhost:5000
pytest -v tests/               # run tests
```

## Run with Docker
```bash
docker build -t employee-directory:v1 .
docker run -d -p 5000:5000 employee-directory:v1
```

## Deploy to EKS (manual)
```bash
aws eks update-kubeconfig --name employee-cluster --region ap-south-1
kubectl apply -f k8s/
kubectl get pods
kubectl get svc employee-directory-svc   # open the EXTERNAL-IP in a browser
```

## CI/CD pipeline (`.github/workflows/ci-cd.yaml`)
On every push to `main` that changes application code:
1. Check out source code
2. Run pytest tests
3. Authenticate to AWS using **GitHub OIDC** (assumes `github-actions-ecr-role`)
4. Build Docker image tagged with the short commit SHA
5. Push the image to Amazon ECR
6. Update `k8s/deployment.yaml` with the new image tag and commit it back

## GitOps with Argo CD
`argocd/application.yaml` points Argo CD at the `k8s/` folder of this repo with automated sync,
pruning and self-heal. When GitHub Actions commits a new image tag, Argo CD detects the change
and rolls out the new version to EKS.

## Author
Shantanu Satav – GitHub: [shantanusatav](https://github.com/shantanusatav)
