control 'coredump-1' do
  title 'Each coredump is emailed to root'
  impact 0.5

  describe command('systemctl show -P OnSuccess systemd-coredump@0-1-0.service') do
    its('stdout') { should cmp "coredump-handler@0-1-0.service\n" }
  end

  # the container's coredumps go to the host, so log a fake one: journalctl -u matches it by COREDUMP_UNIT
  email = <<~'SH'
    printf 'MESSAGE_ID=fc2e22bc6ee647b6b90729ab34a250b1\nCOREDUMP_UNIT=systemd-coredump@0-2-0.service\nMESSAGE=Process 2 (fake-crash) dumped core.\n' | logger --journald &&
    systemctl start coredump-handler@0-2-0.service && sleep 2 && postcat -hbq $(postqueue -j | sed -n 's/.*"queue_id": *"\([^"]*\)".*/\1/p')
  SH
  describe command(email) do
    its('stdout') { should match /^Subject: Coredump on \S+\n.*Process 2 \(fake-crash\) dumped core\./m }
  end
end
