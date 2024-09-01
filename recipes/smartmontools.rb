enable = node['sanity']['smartmontools']['enable']

package 'smartmontools' do
  action enable ? :install : :purge
end

service 'smartmontools' do
  only_if { enable }
  action %i(enable start)
end

file '/etc/smartd.conf' do
  only_if { enable }
  owner 'root'
  group 'root'
  mode '0444'
  notifies :restart, 'service[smartmontools]'
  content [
    'DEVICESCAN -a', # monitor all attributes
    "-m #{node['sanity']['root_email']}", # send warning emails to this address
    '-M exec /usr/share/smartmontools/smartd-runner', # use helper script shipped with https://packages.debian.org/bullseye/amd64/smartmontools/filelist
    '-S on', # enables Attribute Autosave when smartd starts up
    '-W 5,55,60', # log changes of 5+ degrees, or when temp over 55, and warns when over 60 (typical manufacturer max temp is 60 for HDDs and 70 for (NVME) SSDs)
    '-d removable', # continue if the device does not appear to be present when smartd is started
    '-n standby,q', # don't spin up disk when in sleep or standby mode
    '-o on', # enables SMART Automatic Offline Testing when smartd starts up
    '-s (S/../.././02|L/../../6/03)', # short self-test every day between 2-3am, and an extended self test weekly on Saturdays between 3-4am
  ].join(' ')
end
