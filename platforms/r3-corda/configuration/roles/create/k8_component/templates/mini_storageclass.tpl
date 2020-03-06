kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: {{ component_name }}
provisioner: microk8s.io/hostpath
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  encrypted: "true"