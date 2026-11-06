# Record system activity (CPU, memory, disks, network, etc.) to look back at it with sar

enable = node['sanity']['sysstat']['enable']
interval = node['sanity']['sysstat']['interval']

# OnCalendar=*:00/N restarts at minute 0 every hour, so N must divide 60 for every interval to last N minutes
valid_interval = interval.is_a?(Integer) && interval.positive? && (60 % interval).zero?
raise ArgumentError, "node['sanity']['sysstat']['interval'] must be a number of minutes that divides 60 (1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30 or 60), got #{interval.inspect}" if enable && !valid_interval

package 'sysstat' do
  action enable ? :install : :purge
end

# On every configure (e.g. package upgrades by unattended-upgrades), Debian's maintainer scripts enable or disable
# sysstat's systemd units according to ENABLED in /etc/default/sysstat, which defaults to false:
# set it to true so upgrades keep collection on. dpkg-reconfigure syncs the sysstat/enable debconf answer with it.
execute 'enable sysstat data collection' do
  command %(sed -i 's/^ENABLED=.*/ENABLED="true"/' /etc/default/sysstat && dpkg-reconfigure -f noninteractive sysstat)
  only_if { enable }
  not_if %(grep -qx 'ENABLED="true"' /etc/default/sysstat)
end

directory '/etc/systemd/system/sysstat-collect.timer.d' do
  action enable ? :create : :delete
  recursive true
end

# The package collects every 10 minutes, the empty OnCalendar= resets its schedule
systemd_unit 'sysstat-collect.timer.d/sanity.conf' do
  only_if { enable }
  content <<~SYSTEMD
    [Unit]
    Description=Run system activity accounting tool every #{interval} minute(s)

    [Timer]
    OnCalendar=
    OnCalendar=*:00/#{interval}
  SYSTEMD

  verify false # XXX: drop-ins fail verification, like service.d/10-all.conf in sanity::systemd
  action :create
  notifies :restart, 'service[sysstat-collect.timer]'
end

%w(sysstat sysstat-collect.timer sysstat-summary.timer).each do |unit|
  service unit do
    only_if { enable }
    action %i(enable start)
  end
end
