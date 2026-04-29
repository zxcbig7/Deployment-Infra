Write-Host "ArgoCD user: admin"
Write-Host "ArgoCD password:"
$p = kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($p))
Write-Host ""
