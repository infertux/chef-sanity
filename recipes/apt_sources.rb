apt_update do
  action :nothing
end

file '/etc/apt/sources.list' do
  owner 'root'
  group 'root'
  mode '0444'
  notifies :update, 'apt_update', :immediately
  content \
    [
      '# THIS FILE IS MANAGED BY CHEF, DO NOT EDIT MANUALLY, YOUR CHANGES WILL BE OVERWRITTEN!',
      '',
      *node['sanity']['apt_sources']['repositories'],
      '',
    ].join("\n")
end
