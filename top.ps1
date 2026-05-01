while ($true) {
    $nodes     = kubectl top nodes 2>&1
    $pods      = kubectl top pods -A --sort-by=memory 2>&1
    $namespaces = (kubectl get namespaces -o jsonpath="{.items[*].metadata.name}") -split " "
    $nsSummary = foreach ($ns in $namespaces) {
        $podCount = (kubectl get pods -n $ns --no-headers 2>$null | Measure-Object -Line).Lines
        $running  = (kubectl get pods -n $ns --no-headers 2>$null | Select-String "Running" | Measure-Object -Line).Lines
        "{0,-30} pods: {1,3}  running: {2,3}" -f $ns, $podCount, $running
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Clear-Host
    Write-Host "Updated: $timestamp"
    Write-Host ""
    Write-Host "===   Node Summary   ==="
    $nodes
    Write-Host ""
    Write-Host "=== Namespace Summary ==="
    $nsSummary
    Write-Host ""
    $pods

    Start-Sleep 2
}
