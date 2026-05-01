@echo off
echo Starting K8s services...


rem Start Minikube (wait until complete before opening tabs)
minikube status >nul 2>&1
if errorlevel 1 (
    echo Starting Minikube...
    minikube start
    if errorlevel 1 (
        echo Minikube failed to start. Is Docker Desktop running?
        pause
        exit /b 1
    )
) else (
    echo Minikube already running, skipping start.
)

rem Install ArgoCD and ensure CRDs are present
kubectl get namespace argocd >nul 2>&1
if errorlevel 1 (
    echo Installing ArgoCD...
    kubectl create namespace argocd
)
echo Applying ArgoCD manifests...
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo Waiting for ArgoCD CRDs to be ready...
:wait_crd
kubectl get crd applicationsets.argoproj.io >nul 2>&1
if errorlevel 1 (
    timeout /t 5 /nobreak >nul
    kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml >nul 2>&1
    goto wait_crd
)
echo Waiting for ArgoCD server to be ready...
kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s

rem Install ingress-nginx if not present
kubectl get namespace ingress-nginx >nul 2>&1
if errorlevel 1 (
    echo Installing ingress-nginx...
    minikube addons enable ingress
) else (
    echo ingress-nginx already installed.
)

rem Enable metrics-server if not present
kubectl get deployment metrics-server -n kube-system >nul 2>&1
if errorlevel 1 (
    echo Enabling metrics-server...
    minikube addons enable metrics-server
) else (
    echo metrics-server already enabled.
)

rem Enable kubernetes-dashboard if not present
kubectl get namespace kubernetes-dashboard >nul 2>&1
if errorlevel 1 (
    echo Enabling kubernetes-dashboard...
    minikube addons enable dashboard
) else (
    echo kubernetes-dashboard already enabled.
)

rem Setup infra namespace
kubectl get namespace infra >nul 2>&1 || kubectl create namespace infra

rem Configure ArgoCD to watch infra namespace (only if not already set)
kubectl get configmap argocd-cmd-params-cm -n argocd -o jsonpath="{.data.application\.namespaces}" 2>nul | find "infra" >nul 2>&1
if errorlevel 1 (
    echo Configuring ArgoCD to watch infra namespace...
    echo {"data":{"application.namespaces":"infra"}} > "%TEMP%\argocd-patch.json"
    kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge --patch-file "%TEMP%\argocd-patch.json"
    kubectl rollout restart deployment argocd-applicationset-controller -n argocd
    kubectl rollout restart statefulset argocd-application-controller -n argocd
    echo Waiting for ArgoCD controllers to restart...
    kubectl rollout status deployment argocd-applicationset-controller -n argocd
    kubectl rollout status statefulset argocd-application-controller -n argocd
) else (
    echo ArgoCD already watching infra namespace.
)

rem Allow infra namespace apps in default project
kubectl patch appproject default -n argocd --type merge -p "{\"spec\":{\"sourceNamespaces\":[\"infra\"]}}" >nul 2>&1
echo ArgoCD default project allows infra namespace.

rem Wait for API server to be ready
echo Waiting for API server...
:wait_api
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    timeout /t 3 /nobreak >nul
    goto wait_api
)

rem Apply infra app manifests
echo Applying infra manifests...
kubectl apply -f "%~dp0infra\argo-app.yaml"
kubectl apply -f "%~dp0infra\vault-app.yaml"
kubectl apply -f "%~dp0infra\harbor-app.yaml"
kubectl apply -f "%~dp0infra\argocd-ingress.yaml"
kubectl apply -f "%~dp0infra\dashboard-ingress.yaml"
echo.

rem Unseal Vault
echo Waiting for Vault pod to exist...
:wait_vault
kubectl get pod vault-0 -n infra >nul 2>&1
if errorlevel 1 (
    timeout /t 5 /nobreak >nul
    goto wait_vault
)
echo Vault pod found, unsealing...
kubectl exec -n infra vault-0 -- vault operator unseal z6Hs0Q55Aq7x3u1Pg1br8gjikKg6XjYHxxAbb/hVXKlT
kubectl exec -n infra vault-0 -- vault operator unseal MzrsndE9Vzj9fkGndKPfsAk+c+pamFqSKOn0zsDOC6uL
echo.

rem Start all services in Windows Terminal tabs
wt --window new ^
  new-tab --title "argocd-creds" powershell -NoExit -File "%~dp0argocd-creds.ps1" ^
  ; new-tab --title "minikube-tunnel" cmd /k "minikube tunnel" ^
  ; new-tab --title "cloudflared" cmd /k "cloudflared tunnel run k8s-tunnel" ^
  ; new-tab --title "top" powershell -NoExit -File "%~dp0top.ps1"

echo All services started!

echo.
echo ================================
echo  ArgoCD UI    : https://argocd.viclai.idv.tw
echo  K8s Dashboard: https://dashboard.local
echo  Vault UI     : https://vault.viclai.idv.tw
echo  Harbor       : https://harbor.viclai.idv.tw
echo  Docker Data  : \\wsl$\docker-desktop-data\
echo ================================
echo.
pause
