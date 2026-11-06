# Debian 13 nodes configured by ifupdown and dhcpcd, like Debian's installer sets them up
FROM dokken/debian-13 AS dhcpcd
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y ifupdown dhcpcd-base iproute2 procps socat \
  && apt-get purge -y 'exim4*' \
  && apt-get clean
# systemd has no device units in containers: drop ifup@'s dependency on the interface's device so that it can start
RUN sed '/sys-subsystem-net-devices/d' /usr/lib/systemd/system/ifup@.service > /etc/systemd/system/ifup@.service
# systemd-networkd logs the router advertisements it receives and what it does with them, to debug failures
RUN mkdir -p /etc/systemd/system/systemd-networkd.service.d \
  && printf '[Service]\nEnvironment=SYSTEMD_LOG_LEVEL=debug\n' > /etc/systemd/system/systemd-networkd.service.d/debug.conf
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
