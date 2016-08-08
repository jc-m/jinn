#! /bin/bash
# Copyright 2016 Medallia Inc. All rights reserved
# Use of this source code is governed by the Apache 2.0
# license that can be found in the LICENSE file.

set -e
set -x


if [[ -z "$CLUSTER" || -z "$HOSTNAME" ]]; then
  echo "Missing Parameter(s)"
  exit 1
fi

FSID=$(get_property FSID)
CLUSTER=$(get_property CLUSTER)
NBMONS=$(get_property NBMONS)
PGNUM=$(get_property PGNUM)

CEPHUSER="ceph"
CEPHGROUP="ceph"

apt-get -y install ceph

CEPH_CLIENT_KEYRING=$(get_property CEPH_CLIENT_KEYRING)
CEPH_MON_KEYRING=$(get_property CEPH_MON_KEYRING)
CEPH_OSD_KEYRING=$(get_property CEPH_OSD_KEYRING)
CEPH_MDS_KEYRING=$(get_property CEPH_MDS_KEYRING)
CEPH_RGW_KEYRING=$(get_property CEPH_RGW_KEYRING)
# Initialize CEPH config
MON_KEYRING_TMP="/tmp/mon_keyring"
cat >"${MON_KEYRING_TMP}" <<END
[mon.]
key = ${CEPH_MON_KEYRING}
caps mon = "allow *"
[client.admin]
key = ${CEPH_CLIENT_KEYRING}
auid = 0
caps mds = "allow"
caps mon = "allow *"
caps osd = "allow *"
[client.bootstrap-mds]
key = ${CEPH_MDS_KEYRING}
caps mon = "allow profile bootstrap-mds"
[client.bootstrap-osd]
key = ${CEPH_OSD_KEYRING}
caps mon = "allow profile bootstrap-osd"
[client.bootstrap-rgw]
key = ${CEPH_RGW_KEYRING}
caps mon = "allow profile bootstrap-rgw"
END


mkdir -p "/var/lib/ceph/mon/$CLUSTER-$HOSTNAME"
chown $CEPHUSER:$CEPHGROUP "/var/lib/ceph/mon/$CLUSTER-$HOSTNAME"
chmod 0755 "/var/lib/ceph/mon/$CLUSTER-$HOSTNAME"

temp="$(mktemp "/tmp/$CLUSTER.XXXX")"

counter=1
array=()
for i in "${CEPHNODES[@]}"; do 
  array+=("--add $(get_property HOSTNAME "$i") $i:6789")
  (( counter++ ))
done

monmaptool --create ${array[*]} --fsid "$FSID" --clobber "$temp"

mv "$temp" /etc/ceph/monmap
chown $CEPHUSER:$CEPHGROUP /etc/ceph/monmap
chmod 0640 /etc/ceph/monmap

mkdir -p /var/lib/ceph/bootstrap-{osd,mds,rgw}

ceph-mon --setuser $CEPHUSER --setgroup $CEPHGROUP --mkfs -i "$HOSTNAME" --monmap /etc/ceph/monmap --keyring "${MON_KEYRING_TMP}"


touch "/var/lib/ceph/mon/$CLUSTER-$HOSTNAME/done"

touch "/var/lib/ceph/mon/$CLUSTER-$HOSTNAME/upstart"

stop ceph-mon cluster="$CLUSTER" id="$HOSTNAME" || true
start ceph-mon cluster="$CLUSTER" id="$HOSTNAME"
