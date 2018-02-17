default['sanity']['ssh']['authorized_keys'] = []

default['sanity']['iptables']['ssh_authorized_ips'] = %w(0.0.0.0/0) # default to any source IP

default['sanity']['aliases']['root'] = ''

default['sanity']['auto_reboot']['action'] = :create # or :delete
# default['sanity']['auto_reboot']['weekday']['1.2.3.4'] = 1

default['sanity']['mta'] = :postfix # or :msmtp
