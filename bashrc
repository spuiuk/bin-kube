alias kcsmb='kubectl -n samba-operator-system'
alias kcrook='kubectl -n rook-ceph'
alias kc=kubectl
alias ks=kcsmb
alias kr=kcrook

export PATH=$PATH:~/bin-kube/

alias my-nfs="kr get pods|grep ^rook-ceph-nfs-my-nfs-a|grep -v Terminating|sed 's/ .*//'"
