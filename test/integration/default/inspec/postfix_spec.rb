control 'postfix-1' do
  title 'Postfix is listening on IPv4 only' # since IPv6 is disabled in .kitchen.yml
  impact 1.0

  describe service('postfix') do
    it { should be_running }
  end

  describe port(25) do
    it { should be_listening }
    its('protocols') { should cmp %w(tcp) }
    its('addresses') { should cmp %w(0.0.0.0) }
    its('processes') { should cmp %w(master) }
  end
end

control 'postfix-2' do
  title 'Postfix is configured properly'
  impact 0.5

  describe command('postconf -h mynetworks') do
    its('stdout') { should match /127\.0\.0\.[01]/ }
  end

  describe command('postconf -h inet_protocols') do
    its('stdout') { should cmp "ipv4\n" }
  end

  describe command('postconf -h compatibility_level') do
    its('stdout') { should cmp "3.6\n" }
  end

  # deprecated in favor of smtp(d)_tls_security_level
  describe command('postconf -n') do
    its('stdout') { should_not match /^smtpd?_use_tls\b/ }
  end

  describe command('postconf -h smtp_tls_security_level') do
    its('stdout') { should cmp "verify\n" }
  end

  describe command('postconf -h smtpd_tls_security_level') do
    its('stdout') { should cmp "may\n" }
  end

  describe command('postconf -h smtpd_tls_auth_only') do
    its('stdout') { should cmp "yes\n" }
  end

  describe command('postconf -h smtpd_tls_mandatory_protocols') do
    its('stdout') { should cmp ">=TLSv1.3\n" }
  end

  describe command('postconf -h smtpd_tls_protocols') do
    its('stdout') { should cmp ">=TLSv1.3\n" }
  end

  describe command('postconf -h smtp_tls_mandatory_protocols') do
    its('stdout') { should cmp ">=TLSv1.2\n" }
  end

  describe command('postconf -h smtp_tls_protocols') do
    its('stdout') { should cmp ">=TLSv1.2\n" }
  end

  describe command('postconf -h tls_eecdh_auto_curves') do
    its('stdout') { should cmp "X25519MLKEM768 X25519 prime256v1 secp384r1\n" }
  end

  describe command('postconf -h tls_ffdhe_auto_groups') do
    its('stdout') { should cmp "\n" }
  end

  describe command('postconf -h smtpd_tls_mandatory_ciphers') do
    its('stdout') { should cmp "medium\n" }
  end

  describe command('postconf -h tls_preempt_cipherlist') do
    # https://security.stackexchange.com/questions/200176/is-tls-preempt-cipherlist-yes-in-postfix-a-good-idea-nowadays
    its('stdout') { should cmp "no\n" }
  end
end

control 'postfix-2b' do
  title 'Postfix configuration has no warnings'
  impact 0.5

  describe command('postfix check') do
    its('exit_status') { should eq 0 }
    its('stdout') { should cmp '' }
    its('stderr') { should cmp '' }
  end

  # Debian's chroot syncing is disabled since no service runs chrooted
  describe command('postfix chroot query') do
    its('stdout') { should cmp "off\n" }
  end

  describe file('/var/spool/postfix/etc') do
    it { should_not exist }
  end
end

control 'postfix-3' do
  title 'Postfix is working'
  impact 1

  describe command('date | /usr/sbin/sendmail root') do
    its('exit_status') { should eq 0 }
    its('stdout') { should cmp '' }
    its('stderr') { should cmp '' }
  end
end

control 'postfix-4' do
  title 'Postfix is forwarding mails to root'
  impact 1

  command('date | /usr/sbin/sendmail root')
  command('date | /usr/sbin/sendmail nobody')
  command('date | /usr/sbin/sendmail catchall')
  command('sleep 1')

  describe command('mailq') do
    its('exit_status') { should eq 0 }
    its('stderr') { should cmp '' }
  end

  describe file('/var/spool/mail/') do
    it { should be_a_directory }
    it 'should be an empty directory' do
      expect(Dir.glob('/var/spool/mail/*')).to eq []
    end
  end
end

control 'postfix-5' do
  title 'Postfix negotiates TLS properly'
  impact 0.5

  # offering only the post-quantum hybrid group makes the handshake fail if the server doesn't support it
  describe command('openssl s_client -connect 127.0.0.1:25 -starttls smtp -groups X25519MLKEM768 -brief </dev/null 2>&1') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /^Protocol version: TLSv1\.3$/ }
  end

  describe command('openssl s_client -connect 127.0.0.1:25 -starttls smtp -tls1_2 -brief </dev/null 2>&1') do
    its('exit_status') { should_not eq 0 }
  end
end

control 'postfix-6' do
  title 'Postfix sends emails through the relay with SASL authentication'
  impact 1

  describe command('postconf -h relayhost') do
    its('stdout') { should cmp "[smtp.example.local]:587\n" }
  end

  describe command('postconf -h smtp_sasl_auth_enable') do
    its('stdout') { should cmp "yes\n" }
  end

  describe file('/etc/postfix/sasl_passwd') do
    it { should be_owned_by 'root' }
    its('mode') { should cmp '0400' }
  end

  # look up the compiled map, whatever its database type
  describe command('postmap -q "[smtp.example.local]:587" "$(postconf -h smtp_sasl_password_maps)"') do
    its('exit_status') { should eq 0 }
    its('stdout') { should cmp "test@example.local:secret\n" }
  end
end

control 'postfix-7' do
  title 'Postfix sends all emails from root_email through the relay'
  impact 1

  describe command('postconf -h sender_canonical_maps') do
    its('stdout') { should cmp "static:test@example.local\n" }
  end

  # the relay is unreachable so the email stays queued with its rewritten sender
  describe command('printf "Subject: sender test\n\ntest\n" | /usr/sbin/sendmail -f root nobody@example.net && sleep 2 && postqueue -j') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /"sender": ?"test@example\.local"/ }
    its('stdout') { should_not match /"sender": ?"root/ }
  end
end
