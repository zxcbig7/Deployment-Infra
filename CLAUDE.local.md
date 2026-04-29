# Local Personal Settings

## 本機環境
- minikube 跑在 Windows 11（Docker driver）
- start.bat 負責啟動所有服務（minikube tunnel、argocd port-forward、cloudflared）

## 常用快速指令
- ArgoCD UI：https://localhost:8080（帳號 admin）
- K8s Dashboard：minikube dashboard
- 查看所有 pod：kubectl get pods -A

## 目前狀態（更新此區塊）
- prod namespace：frontend + backend 都跑著
- dev / stg namespace：replica 設為 0（省資源）
