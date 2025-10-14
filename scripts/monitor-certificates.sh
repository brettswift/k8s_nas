#!/bin/bash

# Certificate Monitoring Script
# This script monitors certificate status and renewal schedules

set -e

echo "📊 Certificate Status Monitor"
echo "=============================="

# Function to get certificate expiry date
get_cert_expiry() {
    local namespace=$1
    local secret_name=$2
    kubectl get secret $secret_name -n $namespace -o jsonpath='{.data.tls\.crt}' 2>/dev/null | base64 -d | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2
}

# Function to calculate days until expiry
days_until_expiry() {
    local expiry_date=$1
    local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
    local current_epoch=$(date +%s)
    local days=$(( (expiry_epoch - current_epoch) / 86400 ))
    echo $days
}

# Function to check certificate status
check_cert_status() {
    local namespace=$1
    local cert_name=$2
    local secret_name=$3
    
    echo "📋 Certificate: $cert_name (namespace: $namespace)"
    
    # Check certificate resource status
    local status=$(kubectl get certificate $cert_name -n $namespace -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "NotFound")
    echo "  Status: $status"
    
    # Check certificate expiry
    local expiry_date=$(get_cert_expiry $namespace $secret_name)
    if [ -n "$expiry_date" ]; then
        local days_left=$(days_until_expiry "$expiry_date")
        echo "  Expires: $expiry_date"
        echo "  Days until expiry: $days_left"
        
        # Check if renewal is needed
        if [ $days_left -lt 30 ]; then
            echo "  ⚠️  WARNING: Certificate expires in less than 30 days!"
        elif [ $days_left -lt 60 ]; then
            echo "  🔄 Certificate will be renewed soon (within 30 days)"
        else
            echo "  ✅ Certificate is valid for more than 60 days"
        fi
    else
        echo "  ❌ Could not determine expiry date"
    fi
    
    # Check if certificate is being renewed
    local renewal_status=$(kubectl get certificate $cert_name -n $namespace -o jsonpath='{.status.conditions[?(@.type=="Issuing")].status}' 2>/dev/null || echo "False")
    if [ "$renewal_status" = "True" ]; then
        echo "  🔄 Certificate is currently being renewed"
    fi
    
    echo ""
}

# Function to check cert-manager status
check_cert_manager_status() {
    echo "🔧 cert-manager Status"
    echo "======================"
    
    # Check cert-manager pods
    echo "📦 cert-manager Pods:"
    kubectl get pods -n cert-manager -l app.kubernetes.io/name=cert-manager
    
    echo ""
    
    # Check ClusterIssuers
    echo "🌐 ClusterIssuers:"
    kubectl get clusterissuers
    
    echo ""
    
    # Check cert-manager logs for errors
    echo "📋 Recent cert-manager logs (last 10 lines):"
    kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager --tail=10
    
    echo ""
}

# Function to check all certificates
check_all_certificates() {
    echo "📜 All Certificates"
    echo "==================="
    
    # Get all certificates
    kubectl get certificates -A -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,SECRET:.spec.secretName,READY:.status.conditions[?(@.type=='Ready')].status,AGE:.metadata.creationTimestamp"
    
    echo ""
    
    # Check specific certificates
    echo "🔍 Detailed Certificate Status:"
    echo "==============================="
    
    # Check ArgoCD certificate
    if kubectl get certificate home-brettswift-com-tls -n argocd &>/dev/null; then
        check_cert_status "argocd" "home-brettswift-com-tls" "home-brettswift-com-tls"
    else
        echo "❌ ArgoCD certificate not found"
        echo ""
    fi
    
    # Check for other certificates
    local certs=$(kubectl get certificates -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.spec.secretName}{"\n"}{end}')
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local namespace=$(echo $line | cut -d' ' -f1)
            local cert_name=$(echo $line | cut -d' ' -f2)
            local secret_name=$(echo $line | cut -d' ' -f3)
            
            # Skip if we already checked this certificate
            if [ "$namespace" != "argocd" ] || [ "$cert_name" != "home-brettswift-com-tls" ]; then
                check_cert_status "$namespace" "$cert_name" "$secret_name"
            fi
        fi
    done <<< "$certs"
}

# Function to check renewal schedule
check_renewal_schedule() {
    echo "⏰ Renewal Schedule"
    echo "=================="
    
    # Check cert-manager configuration
    echo "📋 cert-manager renewal configuration:"
    kubectl get certificates -A -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,RENEW_BEFORE:.spec.renewBefore"
    
    echo ""
    
    # Check for upcoming renewals
    echo "🔄 Upcoming renewals (certificates expiring within 60 days):"
    local certs=$(kubectl get certificates -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{" "}{.spec.secretName}{"\n"}{end}')
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local namespace=$(echo $line | cut -d' ' -f1)
            local cert_name=$(echo $line | cut -d' ' -f2)
            local secret_name=$(echo $line | cut -d' ' -f3)
            
            local expiry_date=$(get_cert_expiry $namespace $secret_name)
            if [ -n "$expiry_date" ]; then
                local days_left=$(days_until_expiry "$expiry_date")
                if [ $days_left -lt 60 ]; then
                    echo "  - $cert_name ($namespace): $days_left days until expiry"
                fi
            fi
        fi
    done <<< "$certs"
    
    echo ""
}

# Main execution
main() {
    echo "🔍 Starting certificate monitoring..."
    echo ""
    
    # Check cert-manager status
    check_cert_manager_status
    
    # Check all certificates
    check_all_certificates
    
    # Check renewal schedule
    check_renewal_schedule
    
    echo "✅ Certificate monitoring complete!"
    echo ""
    echo "💡 Tips:"
    echo "  - Run this script regularly to monitor certificate health"
    echo "  - Set up alerts for certificates expiring within 30 days"
    echo "  - Check cert-manager logs if certificates fail to renew"
    echo "  - Use 'kubectl get events -A' to see recent certificate events"
}

# Run main function
main
