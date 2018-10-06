case node['platform_family']
when 'rhel'
  # htop package is shipped in EPEL
  include_recipe 'yum-epel::default'
end

package 'htop'
