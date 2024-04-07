To create Application Gateway Ingress Controller make sure the Managed Identity **ingressapplicationgateway-aks-cluster** sholud have below accesses
```
(a) At least Reader access for the resource group in which Application Ingress Controller exists.
(b) Contributor access for the Application Ingress Controller.
```
<br> <br/>
![image](https://github.com/singhritesh85/terraform-azure/assets/56765895/7380c694-81bd-43dd-83be-61c45d952783)
<br> <br/> <br> <br/>
**In this terraform script it has been achieved using as written below**
<br> <br/>
![image](https://github.com/singhritesh85/terraform-azure/assets/56765895/1f158295-c45b-4663-b081-1922b199881b)


