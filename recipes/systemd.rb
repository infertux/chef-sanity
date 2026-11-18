# Inspired by https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html

email = node['sanity']['root_email'].empty? ? 'root' : node['sanity']['root_email'] # root's local mailbox without root_email

directory '/etc/systemd/system/failure-handler@.service.d'

link '/etc/systemd/system/failure-handler@.service.d/10-all.conf' do
  to File::NULL # prevent recursion error "Failed to add dependency on failure-handler@failure-handler@[...], ignoring: Invalid argument"
end

systemd_unit 'failure-handler@.service' do
  content <<~SYSTEMD
    [Unit]
    Description=Send email notification when service exits unexpectedly

    [Service]
    Type=oneshot
    ExecStart=/bin/bash -c 'echo "To: #{email}\\nSubject: Service %i failed on %l\\n\\n$(journalctl --no-pager -n 15 -u %i)" | /usr/sbin/sendmail -t'
  SYSTEMD

  action :create
end

directory '/etc/systemd/system/service.d'

systemd_unit 'service.d/10-all.conf' do
  content <<~CONF
    [Unit]
    OnFailure=failure-handler@%N.service
  CONF

  verify false # XXX: can be safely ignored, this would fail verification even though `systemd-analyze verify` succeeds
  action :create
end

# Email root about each new coredump, which systemd-coredump logs from its own systemd-coredump@.service instance
directory '/etc/systemd/system/systemd-coredump@.service.d'

systemd_unit 'systemd-coredump@.service.d/10-all.conf' do
  content <<~CONF
    [Unit]
    OnSuccess=coredump-handler@%i.service
  CONF

  verify false # XXX: same as service.d/10-all.conf above
  action :create
end

systemd_unit 'coredump-handler@.service' do
  content <<~SYSTEMD
    [Unit]
    Description=Send email notification when a process dumps core

    [Service]
    Type=oneshot
    ExecStart=/bin/bash -c 'journalctl --sync; echo "To: #{email}\\nSubject: Coredump on %l\\n\\n$(journalctl --no-pager --boot=0 -u systemd-coredump@%i.service)" | /usr/sbin/sendmail -t'
  SYSTEMD

  action :create
end
