package value_for_platform_family(
  %w(debian) => 'vrms',
  %w(rhel fedora) => 'vrms-rpm',
)

execute 'vrms' do
  # print output and fail if non-free packages are found
  command value_for_platform_family(
    %w(debian) => 'vrms && test -z "$(vrms -q)"',
    %w(rhel fedora) => 'vrms-rpm || true # skipped as linux-firmware is non-free',
  )
end
