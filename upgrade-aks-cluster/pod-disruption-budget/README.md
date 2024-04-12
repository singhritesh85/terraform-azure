# Pod Disruption Budget 

**Pod disruption budget minimizes the disruptions on the critical applications and provides surity that they remain available.**
<br> <br/>
Pod disruption budget makes minimum number of pods to be available in all the conditions. If any node is drained during maintenance then minimum number of pods are always be available using Pod disruption budget.
<br> <br/>
                         ![image](https://github.com/singhritesh85/terraform-azure/assets/56765895/cc9c5e66-5959-4fb2-8dce-cb19bea1e9b2)
<br> <br/>
Pod disruption budget has three major components
```
(a) Selector (Selector is used to specify which set of Pods PDB will be applied)
(b) minAvailable
(c) maxUnavailable (available in Kubernetes 1.7 and higher)
```
while applying PDB you can select one in between minAvailable and maxUnavailable.
<br> <br/>
In this example I have created two pods(using replicas: 2) and with the selector (app: nginx). Pod disruption budget is created with minimum 33% pods always be available. 
![image](https://github.com/singhritesh85/terraform-azure/assets/56765895/36d6aea6-d295-41bc-9615-fce73c76f140)
![image](https://github.com/singhritesh85/terraform-azure/assets/56765895/95f5d410-351a-4f5e-8921-ad601803cbcf)

As shown in the screenshot above not all the pods are evicted in one go as 33% of the 2 (total pods) is 0.66 which is rounded up to the nearest integer 1 (Reference = https://kubernetes.io/docs/tasks/run-application/configure-pdb/). Hence 1 pod will always be available for serving the request and another 1 pod (as total pods was 2) will be evicted in one go which is also verified with the attached screenshot.
