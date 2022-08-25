package 'smartmontools'

service 'smartmontools' do
  action %i(enable start)
end

file '/etc/smartd.conf' do
  owner 'root'
  group 'root'
  mode '0444'
  notifies :restart, 'service[smartmontools]'
  content [
    'DEVICESCAN -a', # monitor all attributes
    "-m #{node['sanity']['root_email']}", # send warning emails to this address
    '-M exec /usr/share/smartmontools/smartd-runner', # use helper script shipped with https://packages.debian.org/bullseye/amd64/smartmontools/filelist
    '-S on', # enables Attribute Autosave when smartd starts up
    '-W 5,45,50', # log changes of 5+ degrees, or when temp over 45, and warns when over 50 (typical manufacturer max temp is 60)
    '-d removable', # continue if the device does not appear to be present when smartd is started
    '-n standby,q', # don't spin up disk when in sleep or standby mode
    '-o on', # enables SMART Automatic Offline Testing when smartd starts up
    '-s (S/../.././02|L/../../6/03)', # short self-test every day between 2-3am, and an extended self test weekly on Saturdays between 3-4am
  ].join(' ')
end
