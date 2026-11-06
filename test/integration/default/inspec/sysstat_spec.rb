control 'sysstat-1' do
  title 'sysstat records system activity every minute'
  impact 0.5

  describe file('/etc/default/sysstat') do
    its('content') { should match /^ENABLED="true"$/ }
  end

  describe command('debconf-show sysstat') do
    its('stdout') { should match %r{sysstat/enable: true$} }
  end

  units = %w(sysstat.service sysstat-collect.timer sysstat-summary.timer)

  describe command("systemctl is-enabled #{units.join(' ')}") do
    its('stdout') { should eq "enabled\n" * units.size }
  end

  describe command("systemctl is-active #{units.join(' ')}") do
    its('stdout') { should eq "active\n" * units.size }
  end

  # a single OnCalendar entry, the package's one is reset by the drop-in
  describe command('systemctl show --property=TimersCalendar sysstat-collect.timer') do
    its('stdout') { should match %r{\ATimersCalendar=\{ OnCalendar=\*-\*-\* \*:00/1:00 ;[^\n]*\}\n\z} }
  end

  # sysstat.service writes a restart record to the daily data file when it starts
  describe command('test -s "/var/log/sysstat/sa$(date +%d)"') do
    its('exit_status') { should eq 0 }
  end
end
