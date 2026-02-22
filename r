[1mdiff --git a/.github/workflows/ci-cd-pipeline.yml b/.github/workflows/ci-cd-pipeline.yml[m
[1mdeleted file mode 100644[m
[1mindex 11e47d1..0000000[m
[1m--- a/.github/workflows/ci-cd-pipeline.yml[m
[1m+++ /dev/null[m
[36m@@ -1,177 +0,0 @@[m
[31m-name: Backend CI/CD Pipeline[m
[31m-[m
[31m-on:[m
[31m-  push:[m
[31m-    branches: [ "main", "developer" ][m
[31m-  pull_request:[m
[31m-    branches: [ "main", "developer" ][m
[31m-[m
[31m-# Minimum permissions required for OIDC authentication[m
[31m-permissions:[m
[31m-  id-token: write[m
[31m-  contents: read[m
[31m-[m
[31m-env:[m
[31m-  AWS_REGION: us-east-1 # TODO: Change to your actual AWS region[m
[31m-  ECS_CLUSTER: knowscope-cluster[m
[31m-  # Ensure ECR repositories are named matching these[m
[31m-  USER_ECR: knowscope/user-service[m
[31m-  AI_ECR: knowscope/agentic-ai-service[m
[31m-  CONTENT_ECR: knowscope/content-service[m
[31m-[m
[31m-jobs:[m
[31m-  # ==========================================[m
[31m-  # 1. CI / BUILD AND TEST STAGE[m
[31m-  # ==========================================[m
[31m-  ci-build-test:[m
[31m-    name: Build and Test Services[m
[31m-    runs-on: ubuntu-latest[m
[31m-    strategy:[m
[31m-      matrix:[m
[31m-        service: [user_service, agentic_ai_service, content_service][m
[31m-    [m
[31m-    steps:[m
[31m-      - name: Checkout Repository[m
[31m-        uses: actions/checkout@v4[m
[31m-[m
[31m-      - name: Set up Python[m
[31m-        uses: actions/setup-python@v5[m
[31m-        with:[m
[31m-          python-version: '3.13'[m
[31m-          cache: 'pip' # Speeds up installation[m
[31m-[m
[31m-      - name: Install dependencies & Test[m
[31m-        working-directory: backend/${{ matrix.service }}[m
[31m-        run: |[m
[31m-          pip install -r requirements.txt[m
[31m-          python -m py_compile app/main.py[m
[31m-          # Run pytest if tests exist: [m
[31m-          # pytest tests/ || echo "No tests configured yet"[m
[31m-[m
[31m-      - name: Set up Docker Buildx[m
[31m-        uses: docker/setup-buildx-action@v3[m
[31m-[m
[31m-      - name: Build Docker Image (CI check)[m
[31m-        uses: docker/build-push-action@v5[m
[31m-        with:[m
[31m-          context: backend/${{ matrix.service }}[m
[31m-          push: false # Only build to ensure it complies successfully[m
[31m-          tags: ${{ matrix.service }}:test-build[m
[31m-          cache-from: type=gha,scope=${{ matrix.service }}[m
[31m-          cache-to: type=gha,mode=max,scope=${{ matrix.service }}[m
[31m-[m
[31m-  # ==========================================[m
[31m-  # 2. CD / PUSH & DEPLOY TO AWS[m
[31m-  #    (Runs ONLY on push to main/developer)[m
[31m-  # ==========================================[m
[31m-  cd-deploy-aws:[m
[31m-    name: Build, Push to ECR, and Deploy to ECS[m
[31m-    needs: [ci-build-test][m
[31m-    if: github.event_name == 'push'[m
[31m-    runs-on: ubuntu-latest[m
[31m-    [m
[31m-    steps:[m
[31m-      - name: Checkout Repository[m
[31m-        uses: actions/checkout@v4[m
[31m-[m
[31m-      - name: Configure AWS credentials via OIDC[m
[31m-        uses: aws-actions/configure-aws-credentials@v4[m
[31m-        with:[m
[31m-          role-to-assume: ${{ secrets.AWS_OIDC_ROLE_ARN }}[m
[31m-          aws-region: ${{ env.AWS_REGION }}[m
[31m-[m
[31m-      - name: Login to Amazon ECR[m
[31m-        id: login-ecr[m
[31m-        uses: aws-actions/amazon-ecr-login@v2[m
[31m-[m
[31m-      - name: Set up Docker Buildx[m
[31m-        uses: docker/setup-buildx-action@v3[m
[31m-[m
[31m-      - name: Build, tag, and push images to Amazon ECR[m
[31m-        id: build-images[m
[31m-        env:[m
[31m-          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}[m
[31m-          IMAGE_TAG: ${{ github.sha }}[m
[31m-        run: |[m
[31m-          # Function to build and push[m
[31m-          build_and_push() {[m
[31m-            local dir=$1[m
[31m-            local repo=$2[m
[31m-            docker build -t $ECR_REGISTRY/$repo:$IMAGE_TAG -t $ECR_REGISTRY/$repo:latest "$dir"[m
[31m-            docker push $ECR_REGISTRY/$repo:$IMAGE_TAG[m
[31m-            docker push $ECR_REGISTRY/$repo:latest[m
[31m-          }[m
[31m-[m
[31m-          # Build and push backends[m
[31m-          build_and_push backend/user_service $USER_ECR[m
[31m-          build_and_push backend/agentic_ai_service $AI_ECR[m
[31m-          build_and_push backend/content_service $CONTENT_ECR[m
[31m-[m
[31m-      # =========================================================================[m
[31m-      # DEPLOY: USER SERVICE[m
[31m-      # =========================================================================[m
[31m-      - name: Download User Service ECS Task Definition[m
[31m-        run: |[m
[31m-          aws ecs describe-task-definition --task-definition user-service --query taskDefinition > task-definition-user.json[m
[31m-[m
[31m-      - name: Fill in the new image ID in the ECS task definition[m
[31m-        id: task-def-user[m
[31m-        uses: aws-actions/amazon-ecs-render-task-definition@v1[m
[31m-        with:[m
[31m-          task-definition: task-definition-user.json[m
[31m-          container-name: user-service-container[m
[31m-          image: ${{ steps.login-ecr.outputs.registry }}/${{ env.USER_ECR }}:${{ github.sha }}[m
[31m-[m
[31m-      - name: Deploy Amazon ECS task definition (Zero Downtime)[m
[31m-        uses: aws-actions/amazon-ecs-deploy-task-definition@v1[m
[31m-        with:[m
[31m-          task-definition: ${{ steps.task-def-user.outputs.task-definition }}[m
[31m-          service: user-ecs-service[m
[31m-          cluster: ${{ env.ECS_CLUSTER }}[m
[31m-          wait-for-service-stability: true[m
[31m-[m
[31m-      # =========================================================================[m
[31m-      # DEPLOY: AGENTIC AI SERVICE[m
[31m-      # =========================================================================[m
[31m-      - name: Download Agentic AI Service ECS Task Definition[m
[31m-        run: |[m
[31m-          aws ecs describe-task-definition --task-definition agentic-ai-service --query taskDefinition > task-definition-ai.json[m
[31m-[m
[31m-      - name: Fill in the new image ID in the ECS task definition[m
[31m-        id: task-def-ai[m
[31m-        uses: aws-actions/amazon-ecs-render-task-definition@v1[m
[31m-        with:[m
[31m-          task-definition: task-definition-ai.json[m
[31m-          container-name: agentic-ai-service-container[m
[31m-          image: ${{ steps.login-ecr.outputs.registry }}/${{ env.AI_ECR }}:${{ github.sha }}[m
[31m-[m
[31m-      - name: Deploy Amazon ECS task definition (Zero Downtime)[m
[31m-        uses: aws-actions/amazon-ecs-deploy-task-definition@v1[m
[31m-        with:[m
[31m-          task-definition: ${{ steps.task-def-ai.outputs.task-definition }}[m
[31m-          service: agentic-ai-ecs-service[m
[31m-          cluster: ${{ env.ECS_CLUSTER }}[m
[31m-          wait-for-service-stability: true[m
[31m-[m
[31m-      # =========================================================================[m
[31m-      # DEPLOY: CONTENT SERVICE[m
[31m-      # =========================================================================[m
[31m-      - name: Download Content Service ECS Task Definition[m
[31m-        run: |[m
[31m-          aws ecs describe-task-definition --task-definition content-service --query taskDefinition > task-definition-content.json[m
[31m-[m
[31m-      - name: Fill in the new image ID in the ECS task definition[m
[31m-        id: task-def-content[m
[31m-        uses: aws-actions/amazon-ecs-render-task-definition@v1[m
[31m-        with:[m
[31m-          task-definition: task-definition-content.json[m
[31m-          container-name: content-service-container[m
[31m-          image: ${{ steps.login-ecr.outputs.registry }}/${{ env.CONTENT_ECR }}:${{ github.sha }}[m
[