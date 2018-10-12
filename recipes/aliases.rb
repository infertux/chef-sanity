line = "root: #{node['sanity']['aliases']['root']}"

execute "append #{line} to /etc/aliases" do
  user 'root'
  group 'root'
  command "echo '#{line}' >> /etc/aliases"
  not_if "grep -q '#{line}' /etc/aliases"
  notifies :run, 'execute[newaliases]', :immediately
  not_if { node['sanity']['aliases']['root'].empty? }
end

execute 'newaliases' do
  action :nothing
  user 'root'
  group 'root'
  command 'newaliases'
end

# TODO: replace with postfix::aliases
