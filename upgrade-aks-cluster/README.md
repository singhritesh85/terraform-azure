# Upgrade AKS Cluster 
**Before upgradation of AKS Cluster check Pod Disruption Budget. However it is Application owner's responsibility to implement Pod Disruption Budget.**

1. Create an AKS Cluster using the terraform script present in my GitHub Repo https://github.com/singhritesh85/terraform-azure and inside the directory **azure-aks-withoutmanagedprometheusgrafana**.
2. Take the backup of Aks cluster using velero with the help of shell script aks-backup-velero.sh. I have used velero CLI to install the velero server.
3. Provide executable permission to the shell script before executing it.
4. To upgrade AKS Cluster from 1.26 to 1.29 first of all it needs to be upgraded to 1.27 then to 1.28 and finally to 1.29. AKS Cluster cannot be directly updated to 1.29 from 1.26.
```
AKS Cluster 1.26 ---> AKS Cluster 1.27 ---> AKS Cluater 1.28 ---> AKS Cluster 1.29
```
However in this Demo I have upgraded AKS Cluster from 1.28 to 1.29.
<br> <br/>
5. In this terraform script after creation of AKS Cluster with version 1.28 open file main.tf and set the value of the variable kubernetes_version to the desired value of kubernetes version which you want to upgrade your AKS cluster to. In the present demo I have upgraded AKS cluster from 1.28.5 to 1.29.0. You can check different versions of terraform cluster in the file terraform.tfvars and update it as per your need. 


![image](https://github.com/singhritesh85/terraform-azure/assets/56765895/351f4143-afd5-4f41-b15a-611cdb1512ac)

![image](https://github.com/singhritesh85/terraform-azure/assets/56765895/4cc88b6e-378f-4401-9abf-641ab2d6d23e)

