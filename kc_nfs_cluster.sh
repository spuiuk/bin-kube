SMBOPERATORDIR=/home/sprabhu/dev/ocs/samba-operator
ROOKDIR=/home/sprabhu/dev/ocs/rook


echo minikube: Start
#minikube start --nodes=3 --extra-disks=2 --memory 4096 --cpus 2
~/bin-kube/mk_start

#echo: Ad-server: install
#cd $SMBOPERATORDIR
#./tests/test-deploy-ad-server.sh
#cd ..

echo rook-ceph: Install
kubectl create -f $ROOKDIR/deploy/examples/crds.yaml
kubectl create -f $ROOKDIR/deploy/examples/common.yaml
kubectl create -f $ROOKDIR/deploy/examples/operator.yaml
# Patch configmap to enable NFS
kubectl -n rook-ceph patch configmap/rook-ceph-operator-config --type merge \
	-p '{"data":{"ROOK_CSI_ENABLE_NFS":"true"}}'
kubectl create -f $ROOKDIR/deploy/examples/cluster.yaml

echo rook-ceph: Wait for rook-ceph pods to come up
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done
sleep 10;
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done

echo rook-ceph: Install required tools
kubectl create -f $ROOKDIR/deploy/examples/toolbox.yaml
kubectl create -f $ROOKDIR/deploy/examples/pool.yaml
kubectl create -f $ROOKDIR/deploy/examples/filesystem.yaml

echo rook-ceph: Wait for rook-ceph toolbox pods to come up
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done
sleep 10;
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done

echo rook-ceph: Setup cephfs storage class
kubectl apply -f $ROOKDIR/deploy/examples/csi/cephfs/storageclass.yaml
kubectl patch storageclass rook-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

echo
kubectl get storageclass
echo

echo rook-ceph: enable nfs
TOOLBOX_CONTAINER=$(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}')
#kubectl -n rook-ceph exec -it $TOOLBOX_CONTAINER -- ceph mgr module enable rook
#kubectl -n rook-ceph exec -it $TOOLBOX_CONTAINER -- ceph mgr module enable nfs
#kubectl -n rook-ceph exec -it $TOOLBOX_CONTAINER -- ceph orch set backend rook
echo

echo rook-ceph: Setup ceph-nfs
kubectl apply -f $ROOKDIR/deploy/examples/csi/nfs/rbac.yaml
kubectl create -f $ROOKDIR/deploy/examples/nfs.yaml
kubectl apply -f $ROOKDIR/deploy/examples/csi/nfs/storageclass.yaml

echo rook-nfs: Setup demo
kubectl apply -f $ROOKDIR/deploy/examples/csi/nfs/pvc.yaml
kubectl apply -f $ROOKDIR/deploy/examples/csi/nfs/pod.yaml
