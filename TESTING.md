You can run a full build locally using Kitchen CI and Docker with `bundle exec rake` or `./test.sh`.

The switch from ifupdown to systemd-networkd can't be tested with Test Kitchen, run `sudo test/network/test.sh` for it (requires Docker, iproute2, dnsmasq and python3).
