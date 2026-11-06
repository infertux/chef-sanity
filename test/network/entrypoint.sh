#!/bin/sh
# PID 1 of the nodes: starts systemd once test.sh has plugged eth0 in, so that it's there at boot like a real NIC

if [ "$(stat -fc %T /sys/fs/cgroup)" != cgroup2fs ]; then
  # systemd 257 needs cgroup v2, mount it if Docker uses cgroup v1
  umount -R /sys/fs/cgroup && mount -t cgroup2 none /sys/fs/cgroup
fi

while [ ! -e /sys/class/net/eth0 ]; do sleep 0.1; done

exec /usr/lib/systemd/systemd
