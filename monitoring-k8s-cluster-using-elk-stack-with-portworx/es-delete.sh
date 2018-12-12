kubectl delete -f portworx-sc.yaml

kubectl delete -f es-master-svc.yaml

kubectl delete -f es-master-sts.yaml

kubectl delete -f es-coordinator-deployment.yaml

kubectl delete -f es-coordinator-svc.yaml

kubectl delete -f es-data-svc.yaml

kubectl delete -f es-data-sts.yaml

kubectl get all
