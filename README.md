# Gemini Chat — Full-Stack AI Chat Application

A production-grade Gemini-like AI chat application with file processing, automated CI/CD, and AWS infrastructure.

![Next.js](https://img.shields.io/badge/Next.js-15-black?logo=next.js)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi)
![AWS](https://img.shields.io/badge/AWS-ECS%20Fargate-FF9900?logo=amazon-aws)
![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?logo=mongodb)

## ✨ Features

- **AI Chat** — Powered by Google Gemini 2.0 Flash
- **File Analysis** — Upload & analyze PDFs, Word docs, Excel sheets, images
- **Conversation History** — Stored in MongoDB Atlas
- **File Preview** — Inline display for images, document cards for files
- **Markdown Rendering** — Code blocks, tables, lists in AI responses
- **Dark Theme** — Gemini-inspired premium dark UI
- **Responsive** — Mobile-friendly sidebar & chat

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js 15, TypeScript, Tailwind CSS 4 |
| Backend | Python, FastAPI, Google Gemini API |
| Database | MongoDB Atlas (Motor async driver) |
| Cache | Redis / AWS ElastiCache |
| Infrastructure | AWS ECS Fargate, ALB, ECR |
| CI/CD | GitHub Actions |
| Monitoring | CloudWatch, Grafana |

## 🚀 Quick Start (Local)

### Prerequisites
- Node.js 20+, Python 3.12+, Docker & Docker Compose
- Google Gemini API Key
- MongoDB Atlas URI

### 1. Clone & Configure

```bash
git clone <your-repo-url>
cd aws-deploy-auto

# Backend
cp backend/.env.example backend/.env
# Edit backend/.env with your GEMINI_API_KEY and MONGODB_URI

# Frontend
cp frontend/.env.local.example frontend/.env.local
```

### 2. Run with Docker Compose

```bash
docker-compose up --build
```

- Frontend: http://localhost:3000
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs

### 3. Run Without Docker

```bash
# Backend
cd backend
pip install -r requirements.txt
python main.py

# Frontend (separate terminal)
cd frontend
npm install
npm run dev
```

## ☁️ AWS Deployment

### Prerequisites
- AWS CLI configured (`aws configure`)
- Docker installed

### Step-by-Step Deployment

```bash
# 1. Configure environment
cp infra/env.sh infra/env.local.sh
# Edit infra/env.sh with your credentials

# 2. Run infrastructure scripts in order
cd infra
bash 01-ecr-setup.sh           # Create ECR repos
bash 02-vpc-networking.sh      # VPC, subnets, security groups
bash 03-alb-setup.sh          # Application Load Balancer
bash 04-elasticache-setup.sh  # Redis cache
bash 05-ecs-cluster.sh        # ECS cluster + IAM roles
bash 06-task-definitions.sh   # Fargate task definitions
bash 07-ecs-services.sh       # Create & start services
bash 08-cloudwatch-setup.sh   # Logging & monitoring
bash 09-grafana-setup.sh      # Grafana dashboard
```

### Push Docker Images to ECR

```bash
# Login to ECR
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com

# Build & push
docker build -t <ecr-backend-uri>:latest ./backend
docker push <ecr-backend-uri>:latest

docker build -t <ecr-frontend-uri>:latest ./frontend
docker push <ecr-frontend-uri>:latest
```

### CI/CD (Automatic Deployments)

Add these GitHub Secrets:

| Secret | Description |
|--------|------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM access key |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key |
| `AWS_REGION` | AWS region (e.g., ap-south-1) |
| `ECR_BACKEND_REPO` | Backend ECR repo name |
| `ECR_FRONTEND_REPO` | Frontend ECR repo name |
| `MONGODB_URI` | MongoDB Atlas connection string |
| `GEMINI_API_KEY` | Google Gemini API key |
| `API_URL` | ALB DNS (http://your-alb-dns) |

Push to `main` → GitHub Actions builds → ECR push → ECS rolling deploy.

### Teardown

```bash
bash infra/teardown.sh
```

## 📊 Monitoring

- **CloudWatch**: Logs, metrics, alarms (auto-configured)
- **Grafana**: Import `infra/grafana/dashboard.json` (see `infra/grafana/README.md`)
- **Prometheus**: Metrics at `/api/metrics`

## 📁 Project Structure

```
├── backend/              # FastAPI backend
│   ├── main.py           # Entry point
│   ├── config.py         # Environment config
│   ├── routers/chat.py   # API endpoints
│   ├── services/         # Gemini, file, cache services
│   ├── models/           # Pydantic models
│   ├── db/               # MongoDB connection
│   └── Dockerfile
├── frontend/             # Next.js frontend
│   ├── src/app/          # Pages & layout
│   ├── src/components/   # React components
│   ├── src/lib/          # API client
│   └── Dockerfile
├── infra/                # AWS CLI scripts (01-09)
├── .github/workflows/    # CI/CD pipeline
└── docker-compose.yml    # Local development
```

## 📄 License

MIT
