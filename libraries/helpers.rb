require 'digest'

class Sanity
  # Generic helpers
  module Helpers
    # Returns a deterministic random number inferred from the hostname
    def drand(modulus)
      Digest::SHA256.hexdigest(node['hostname'])[0..1].to_i(16) % modulus
    end
  end
end
