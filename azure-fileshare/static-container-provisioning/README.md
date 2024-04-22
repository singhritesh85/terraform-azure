1. Only for this demostration I have create the AKS Cluster using the terraform script **azure-aks-storageaccount-container**. It will create AKS cluster, Storage Account and Container inside the Storage Account.
2. Upload the files in the Container created inside the Storage Account.
3. create kubernetes secret using the command below
```
kubectl create secret generic azure-secret --from-literal=azurestorageaccountname=aksff916264 --from-literal=azurestorageaccountkey=OEv6yXXXXXXXXXXXX2KauQtrF3SXXXXXXXXXXXXXXXXXKXvE4yZKMvLMyXXXXXXXXXXXXXXXXX+AStOgassA==
```
4. kubectl get sc  ### check the storage class
5. create namespace, pv, pvc, and deployment using the file pv-pvc-deployment.yaml and you will check the files which you had uploaded in storageaccount's container will be available at the path /usr/share/nginx/html inside the pod.
