Deploy elastic stack with persistent storage-portworx on kubernetes

Steps:
1. Create storage class:
	kubectl apply -f portworx-sc.yaml

2. Install elasticsearch cluster:
	service: kubectl apply -f es-master-svc.yaml
	statefulset: kubectl apply -f es-master-sts.yaml

3. Create co-ordinator:
	Deployment: kubectl apply -f es-coordinator-deployment.yaml
	Service: kubectl apply -f es-coordinator-svc.yaml
 	
   Check running pods:	kubectl get pods -w

4. Create data nodes and headless services:
	service: kubectl apply -f es-data-svc.yaml
	statefulse:  kubectl apply -f es-data-sts.yaml
 
   Check cluster state: kubectl get all

5. Verify elasticsearch installation:
	- kubectl exec -it elasticsearch-master-0  curl 'http://elasticsearch.default.svc:9200'
	- kubectl exec -it elasticsearch-master-0  curl 'http://elasticsearch.default.svc:9200/_cat/nodes?v'

6. Deploy Kibana  :
	Service: kubectl apply -f kibana-svc.yaml
	Deployment: kubectl apply -f kibana-deployment.yaml
	
	Check kinana service port for access: kubectl get svc | grep kibana
	
     Access Kibana using any node ip of k8s cluster and node port provided by above command like:
	http://master-node-ip:31469


K8S cluster monitoring:
1. Deploy filebeat as daemonset to ship logs into elasticsearch and monitor using kibana:
	NOTE : Update following details in filebeat-kubernetes.yaml
	- name: ELASTICSEARCH_HOST
 	value: elasticsearch
	- name: ELASTICSEARCH_PORT
 	value: "9200"
	- name: ELASTICSEARCH_USERNAME
 	value: elastic
	- name: ELASTICSEARCH_PASSWORD
 	value: changeme
	
	Deploy filebeat:
	- kubectl apply -f filebeat-kubernetes.yaml

2. Once the above deployment successfully done, check filebeat is running on all the nodes of cluster using command : `ps -elf | grep filebeat`

3. Access kibana, Management -> Index Patterns -> Create Index Pattern -> search for filebeat-* -> Next step -> select @timestamp -> Create index pattern.
   Check index data : Discover -> filebeat-*

This way you can setup elasticsearch cluster, kibana, filebeat on kubernetes with persistent volume manager Portworx and monitor k8s using same.
For more details :
	-  https://docs.portworx.com/portworx-install-with-kubernetes/application-install-with-kubernetes/elastic-search-and-kibana/

