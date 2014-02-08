#find "$@" -ls
#cat $1/.git/objects/79/tmp_obj_B3hF4h
ls -o /tmp/replayed_snapshot/.git/index /tmp/replayed_snapshot_diskops/.git/index
diff -a -r /tmp/replayed_snapshot /tmp/replayed_snapshot_diskops
