# ECS Blue/Green Deployment with Strapi

This project deploys a Strapi application to Amazon ECS Fargate using Blue/Green deployment with AWS CodeDeploy, fully automated with GitHub Actions CI/CD.

# STEP 1 — Create Strapi Application

Install Strapi locally:

npx create-strapi-app@latest strapi --quickstart

Go inside the folder:

cd strapi

# Test locally:

npm run develop

Open:

http://localhost:1337/admin

Stop the server.

# STEP 2 — Dockerize Strapi

Create a Dockerfile inside strapi/:

FROM node:18

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

EXPOSE 1337

CMD ["npm","run","start"]

# Test locally:
- docker build -t strapi .
- docker run -p 1337:1337 strapi

# STEP 3 - create ecr and push the image to ecr

# Create an ECR repository using Terraform.

Example ECR URI:
811738710312.dkr.ecr.us-east-1.amazonaws.com/strapi-bluegreen-ecr

- docker tag strapi:latest 811738710312.dkr.ecr.us-east-1.amazonaws.com/ecs-bluegreen-ecr:latest
- docker push 811738710312.dkr.ecr.us-east-1.amazonaws.com/ecs-bluegreen-ecr:latest


# STEP 4 — Provision Infrastructure with Terraform

Go to your infra folder:

cd infra
terraform init
terraform plan
terraform apply

# Terraform creates:

- Default VPC usage
- Private subnets
- NAT Gateway
- Security groups
- RDS PostgreSQL
- ALB (Port 80 = Production, 9000 = Test)
- ECS Cluster
- ECS Service (CodeDeploy type)
- ECR Repository
- CodeDeploy Application & Deployment Group

After apply, note:
alb_dns

# STEP 5 — Push Code to GitHub

Push your project to GitHub:

git init
git add .
git commit -m "Initial commit"
git push origin main

# STEP 6 — Add GitHub Secrets

In your GitHub repository:
Settings → Secrets → Actions → New repository secret

Add:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY

These must have permissions for:

- ECS
- ECR
- CodeDeploy
- RDS
- ALB

# STEP 7 — CI Workflow (Build & Push Image)

When you push to main:

GitHub Actions will:

- Build Docker image
- Tag with commit SHA
- Push image to Amazon ECR
- Save image URI as artifact

# STEP 8 — CD Workflow (Deploy to ECS)

After CI success:

CD workflow will:

- Fetch new image URI
- Create new ECS task definition revision
- Generate appspec.json dynamically
- Trigger AWS CodeDeploy deployment
- Wait for deployment success

# STEP 9 — Blue/Green Deployment Process

Deployment flow:

- New task definition created
- Green task set created
- Green target group health check
- Traffic shifts from Blue → Green
- Blue terminated after success

If deployment fails:

CodeDeploy automatically rolls back to Blue
Zero downtime deployment 

# STEP 10 — Access the Application

After deployment success:

Open your ALB DNS:

http://<alb_dns>

Production traffic → Port 80
Test traffic → Port 9000

To access admin:

http://<alb_dns>/admin
