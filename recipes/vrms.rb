package 'vrms'

execute 'vrms' do
  # print output and fail if non-free packages are found
  command 'vrms && test -z "$(vrms -q)"'
end
