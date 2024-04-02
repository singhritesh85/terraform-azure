For static smb fileshare create the secret as written below and use the secret name in the yaml file static-smb-fileshare.yaml.
```
kubectl create secret generic azure-secret --from-literal=azurestorageaccountname=tachotacho --from-literal=azurestorageaccountkey=frKmXXXXXXXXXe7stuWKvjYKoKXXXXXXXuZnFrYX+7OPVMxxxxxxxxxDDq47fIyaA1Ug+CXXXXXXXXSto2iJqA==
```
