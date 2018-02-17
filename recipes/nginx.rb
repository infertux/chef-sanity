node.normal['nginx']['default_site_enabled'] = false
node.normal['nginx']['server_tokens'] = 'off'
node.normal['nginx']['server_names_hash_bucket_size'] = 128 # needed for ACME Let's Encrypt long domain name verification
