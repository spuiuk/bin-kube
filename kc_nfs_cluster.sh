ROOKDIR=/home/sprabhu/data/ocs/rook

echo minikube: Start
#minikube start --nodes=3 --extra-disks=2 --memory 4096 --cpus 2
~/bin-kube/mk_start

echo rook-ceph: Install
kubectl create -f $ROOKDIR/deploy/examples/crds.yaml -f $ROOKDIR/deploy/examples/common.yaml -f $ROOKDIR/deploy/examples/operator.yaml
echo rook-ceph: Wait for rook-ceph pods to come up
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done
sleep 10;
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done

echo rook-ceph: Enable NFS
# Patch configmap to enable NFS
kubectl -n rook-ceph patch configmap/rook-ceph-operator-config --type merge \
	-p '{"data":{"ROOK_CSI_ENABLE_NFS":"true"}}'
# Patch configmap to disable block devices exported by ceph -- To reduce resource usage
kubectl -n rook-ceph patch configmap/rook-ceph-operator-config --type merge \
	-p '{"data":{"ROOK_CSI_ENABLE_RBD":"false"}}'
# Start up cluster
kubectl create -f $ROOKDIR/deploy/examples/cluster.yaml
echo rook-ceph: Wait for rook-ceph pods to come up
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done
sleep 10;
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done

echo rook-ceph: Install tool box. This is the container with tools required to manipulate ceph
kubectl create -f $ROOKDIR/deploy/examples/toolbox.yaml

# Create a filesystem - This filesystem will be exported by NFS
kubectl create -f $ROOKDIR/deploy/examples/filesystem.yaml

echo rook-ceph: Wait for rook-ceph toolbox pods to come up
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done
sleep 10;
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done

# Other ceph stuff to set cephfs as default for storageclass
echo rook-ceph: Setup cephfs storage class
kubectl apply -f $ROOKDIR/deploy/examples/csi/cephfs/storageclass.yaml
kubectl patch storageclass rook-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

echo
kubectl get storageclass
echo

echo rook-ceph: setup cephnfs sample.
# Create CephNFS resource - my-nfs from rook samples
kubectl create -f $ROOKDIR/deploy/examples/nfs.yaml

#short delay to allow ceph-nfs to comeup
sleep 10
# Create the nfs export
kc_ceph_tools ceph nfs export create cephfs my-nfs /myfs myfs


#TOOLBOX_CONTAINER=$(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}')

#echo rook-ceph: Setup csi nfs
# kubectl apply -f $ROOKDIR/deploy/examples/csi/nfs/rbac.yaml
# kubectl apply -f $ROOKDIR/deploy/examples/csi/nfs/storageclass.yaml
#echo rook-nfs: Setup demo
# kubectl apply -f $ROOKDIR/deploy/examples/csi/nfs/pvc.yaml
#kubectl apply -f $ROOKDIR/deploy/examples/csi/nfs/pod.yaml

# https://rook.github.io/docs/rook/v1.9/ceph-nfs-crd.html#creating-exports
