ROOKDIR=/home/sprabhu/dev/ocs/rook
echo minikube: Start
#minikube start --nodes=3 --extra-disks=2 --memory 4096 --cpus 2
~/bin-kube/mk_start

echo rook-ceph: Install
kubectl create -f $ROOKDIR/deploy/examples/crds.yaml
kubectl create -f $ROOKDIR/deploy/examples/common.yaml
kubectl create -f $ROOKDIR/deploy/examples/operator.yaml
kubectl create -f $ROOKDIR/deploy/examples/cluster.yaml

echo rook-ceph: Wait for rook-ceph pods to come up
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done
sleep 10;
while kubectl -n rook-ceph get pods |grep -v ^NAME|egrep -v 'Running|Completed'; do sleep 5; done

echo rook-ceph: Install required tools
kubectl create -f $ROOKDIR/deploy/examples/toolbox.yaml
kubectl create -f $ROOKDIR/deploy/examples/pool.yaml
kubectl create -f $ROOKDIR/deploy/examples/filesystem.yaml

echo rook-ceph: Setup cephfs storage class
kubectl apply -f $ROOKDIR/deploy/examples/csi/cephfs/storageclass.yaml
kubectl patch storageclass rook-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

echo
kubectl get storageclass
echo

echo samba-operator: Install
cd $SMBOPERATORDIR
./mydeploy.sh
#make DEVELOPER=1 deploy
