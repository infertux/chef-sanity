# Fluent Bit

include_recipe 'fluentbit::default'
include_recipe 'fluentbit::forward'

include_recipe 'fluentbit::iptables'
include_recipe 'fluentbit::mail'
include_recipe 'fluentbit::monit'
