control 'postfix-1' do
  title 'Postfix is listening'
  impact 1.0

  describe service('postfix') do
    it { should be_running }
  end

  describe port(25) do
    it { should be_listening }
    its('protocols') { should cmp %w(tcp tcp6) }
    its('addresses') { should cmp %w(0.0.0.0 ::) }
    its('processes') { should cmp %w(master) }
  end
end

control 'postfix-2' do
  title 'Postfix is configured properly'
  impact 0.5

  describe command('postconf -h mynetworks') do
    its('stdout') { should match /127\.0\.0\.[01]/ }
  end

  describe command('postconf -h smtp_use_tls') do
    its('stdout') { should cmp "yes\n" }
  end

  describe command('postconf -h smtpd_use_tls') do
    its('stdout') { should cmp "yes\n" }
  end

  describe command('postconf -h smtpd_tls_security_level') do
    its('stdout') { should cmp "may\n" }
  end

  describe command('postconf -h smtpd_tls_auth_only') do
    its('stdout') { should cmp "yes\n" }
  end

  describe command('postconf -h smtpd_tls_mandatory_protocols') do
    its('stdout') { should cmp "!SSLv2,!SSLv3,!TLSv1,!TLSv1.1\n" }
  end

  describe command('postconf -h smtpd_tls_protocols') do
    its('stdout') { should cmp "!SSLv2,!SSLv3,!TLSv1,!TLSv1.1\n" }
  end

  describe command('postconf -h smtpd_tls_mandatory_ciphers') do
    its('stdout') { should cmp "medium\n" }
  end

  describe command('postconf -h tls_preempt_cipherlist') do
    its('stdout') { should cmp "yes\n" }
  end

  describe command('postconf -h tls_medium_cipherlist') do
    its('stdout') { should cmp "AES128+EECDH:AES128+EDH\n" }
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
