#cloud-config
# vim: syntax=yaml
#
# This is the configuration syntax that the write_files module
# will know how to understand. encoding can be given b64 or gzip or (gz+b64).
# The content will be decoded accordingly and then written to the path that is
# provided.
#
# Note: Content strings here are truncated for example purposes.
write_files:
-   content: |
        AZSUBNETS="${azSubnet}"
        SLAVES="${nodes}"
        MONITORS="${cephnodes}"
        CONTROLLERS="${controllers}"
        ROLES="${roles}"
        CIDR="${quaggaCidr}"
        VPC_CIDR="${vpcCidr}"
        CLUSTERNAME="${clusterName}"
        DC_NAME="${dcname}"
        QUORUM="${quorum}"
        NET_IP="${netip}"
        MAIN_IF="eth0"
    path: /etc/bootstrap/env.sh
    permissions: '0644'
    owner: root:root