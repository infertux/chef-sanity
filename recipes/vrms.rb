package value_for_platform_family(
  %w(debian) => 'vrms',
  %w(rhel fedora) => 'vrms-rpm',
)

execute 'vrms' do
  # print output and fail if non-free packages are found
  command value_for_platform_family(
    %w(debian) => 'vrms && test -z "$(vrms -q)"',

    # Example output:
    # > 356 free packages
    # > 1 non-free packages
    # >  - chef
    %w(rhel fedora) => 'vrms-rpm && test "$(vrms-rpm | grep -Ev \'^ - chef$\' | wc -l)" = "2"',
  )
end
