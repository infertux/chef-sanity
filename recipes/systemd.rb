# Inspired by https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html

directory '/etc/systemd/system/failure-handler@.service.d'

link '/etc/systemd/system/failure-handler@.service.d/10-all.conf' do
  to '/dev/null' # prevent recursion error "Failed to add dependency on failure-handler@failure-handler@[...], ignoring: Invalid argument"
end

systemd_unit 'failure-handler@.service' do
  content <<~SYSTEMD
    [Unit]
    Description=Send email notification when service exits unexpectedly

    [Service]
    Type=oneshot
    ExecStart=/bin/bash -c 'echo "Service %i failed on %l\\n\\n$(journalctl --no-pager -n 15 -u %i)" | /usr/bin/mail #{node['sanity']['root_email']}'
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
