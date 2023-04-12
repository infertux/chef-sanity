package value_for_platform_family(
  %w(debian) => 'vrms',
)

execute 'vrms' do
  # print output and fail if non-free packages are found
  command value_for_platform(
    'debian' => {
      '10' => "vrms -s | grep -E '(rms would be proud\.|#{node['sanity']['vrms']['whitelist']})$'",
      '11' => "vrms -s | grep -E '(rms would be proud\.|#{node['sanity']['vrms']['whitelist']})$'",
    },
    'ubuntu' => {
      '23.04' => "vrms -s | grep -E '(No non-free or contrib packages installed|#{node['sanity']['vrms']['whitelist']})'",
    },
  )
end
