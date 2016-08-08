#! /bin/bash
# Copyright 2016 Medallia Inc. All rights reserved
# Use of this source code is governed by the Apache 2.0
# license that can be found in the LICENSE file.

set -e
set -x
export DEBIAN_FRONTEND=noninteractive

RELEASE=infernalis

if [[ -z "$HOSTNAME" ]]; then
  echo "Missing Parameter(s)"
  exit 1
fi

RELEASE=jewel
CEPHUSER="ceph"
CEPHGROUP="ceph"

FSID=$(get_property FSID)
PGNUM=$(get_property PGNUM)
NBMONS=$(get_property NBMONS)
CLUSTER=$(get_property CLUSTER)


# Ceph Repo
add-repo ceph http://download.ceph.com/debian-${RELEASE}/ "$(lsb_release -sc)" main 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'

# Ceph Package Install
apt-get -y install ceph-common ceph-fs-common

cat > /etc/ceph/ceph.conf <<- END
  [global]
  fsid = $FSID
  mon_host = $(get_property CEPH_MONITORS)
  auth_cluster_required = cephx
  auth_service_required = cephx
  auth_client_required = cephx
  rbd default features = 1
  filestore_xattr_use_omap = true
  osd crush chooseleaf type = 0
  osd journal size = 100
  osd pool default pg num = $PGNUM
  osd pool default pgp num = $PGNUM
  osd pool default size = $NBMONS
END

# Wrapper for Ceph RBD that prevents mapping an image already watched
#dpkg-divert --divert /usr/bin/rbd.original --rename /usr/bin/rbd
#install_web_file "/ceph/rbd-wrapper" "/usr/bin/rbd"
#chmod 755 /usr/bin/rbd

#install_web_file "/ceph/remove-rbd-own-locks" "/usr/bin/remove-rbd-own-locks"
#chmod 755 /usr/bin/remove-rbd-own-locks
CEPH_CLIENT_KEYRING=$(get_property CEPH_CLIENT_KEYRING)

cat >/etc/ceph/"${CLUSTER}".client.admin.keyring <<END
[client.admin]
key = ${CEPH_CLIENT_KEYRING}
auid = 0
caps mds = "allow"
caps mon = "allow *"
caps osd = "allow *"
END

chown "$USER":"$GROUP" "/etc/ceph/$CLUSTER.client.admin.keyring"
chmod 0640 "/etc/ceph/$CLUSTER.client.admin.keyring"

