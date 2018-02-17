# Remove unwanted packages often installed by default

package %w(nfs-common rpcbind bind9 sysstat) do
  action :purge
end
