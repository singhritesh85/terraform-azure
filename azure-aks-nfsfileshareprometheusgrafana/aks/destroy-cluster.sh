#!/bin/bash

terraform state rm module.aks.kubernetes_namespace.monitor_namespace
terraform state rm module.aks.kubernetes_storage_class.azurefile
terraform state rm module.aks.helm_release.prometheus
terraform state rm module.aks.helm_release.grafana

echo "Listing Resources within the Terraform state"

terraform state list

terraform destroy -auto-approve
