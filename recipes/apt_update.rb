# Make sure apt caches are up-to-date

apt_update 'update' do
  action :update
end
