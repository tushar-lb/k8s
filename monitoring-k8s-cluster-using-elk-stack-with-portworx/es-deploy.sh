
kubectl apply -f portworx-sc.yaml

kubectl get all

kubectl apply -f portworx-sc.yaml

kubectl apply -f es-master-svc.yaml

kubectl apply -f es-master-sts.yaml

kubectl apply -f es-coordinator-deployment.yaml

kubectl apply -f es-coordinator-svc.yaml

kubectl apply -f es-data-svc.yaml

kubectl apply -f es-data-sts.yaml
