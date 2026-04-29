@echo off
echo Starting K8s services...
echo.
echo ================================
echo  ArgoCD UI    : https://localhost:8080
echo  K8s Dashboard: auto opens in browser
echo ================================
echo.

rem Start Minikube (wait until complete before opening tabs)
for /f "tokens=*" %%s in ('minikube status --format "{{.Host}}" 2^>nul') do set MINIKUBE_STATUS=%%s
if not "%MINIKUBE_STATUS%"=="Running" (
    echo Starting Minikube...
    minikube start
) else (
    echo Minikube already running, skipping start.
)

rem Start all services in Windows Terminal tabs
wt --window new ^
  new-tab --title "argocd-creds" powershell -NoExit -File "%~dp0argocd-creds.ps1" ^
  ; new-tab --title "minikube-tunnel" cmd /k "minikube tunnel" ^
  ; new-tab --title "argocd" cmd /k "kubectl port-forward svc/argocd-server -n argocd 8080:443" ^
  ; new-tab --title "cloudflared" cmd /k "cloudflared tunnel run k8s-tunnel" ^
  ; new-tab --title "dashboard" cmd /k "minikube dashboard" ^
  ; new-tab --title "top" powershell -NoExit -File "%~dp0top.ps1"

echo All services started!
pause
