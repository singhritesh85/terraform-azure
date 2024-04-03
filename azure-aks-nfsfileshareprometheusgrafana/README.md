1. To create the cluster first of all provide the values of the variables as written below
```
(a) k8s_management_node_rg
(b) k8s_management_node_vnet
(c) k8s_management_node_vnet_id


The variable k8s_management_node_rg represents the Resource Group of Terraform-Server or k8s-management-node's **vnet**.
The variable k8s_management_node_vnet represents the **VNet** of Terraform-Server or k8s-management-node.
The variable k8s_management_node_vnet_id represents the **Resource ID** of Terraform-Server of k8s-management-node's **vnet**.
```

3. To create the cluster run the command **terraform apply -auto-approve** from the aks directory.

4. To desytoy the cluster run the shell script **destroy-cluster.sh** from the aks director. 
