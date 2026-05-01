$p = kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"
$password = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($p))

Write-Host "================================"
Write-Host "ArgoCD  admin / $password"
Write-Host "================================"
Write-Host "  ArgoCD UI    : https://argocd.viclai.idv.tw"
Write-Host "  K8s Dashboard: https://dashboard.local"
Write-Host "  Vault UI     : https://vault.viclai.idv.tw"
Write-Host "  Harbor       : https://harbor.viclai.idv.tw"
Write-Host "  Docker Data  : \\wsl$\docker-desktop-data\"
Write-Host "================================"
