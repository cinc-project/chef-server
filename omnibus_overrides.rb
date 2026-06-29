#
# When updating this, check doc/FrequentTasks.md for checklists to ensure all
# the various usages are updated in lockstep
#
# Only deliberate pins remain here; every other component now falls through to
# the omnibus-software default (latest). Removed (now using omnibus-software
# defaults): omnibus-ctl, ohai, logrotate (3.22.0), libffi (3.6.0, >= the 3.4.7
# EL10 fix), runit (2.3.1), gecode (6.2.0, unchanged), perl (5.42.2),
# openresty (1.31.1.1), sqitch (1.6.1).

# Platform runtimes — pinned to a specific major on purpose:
override :erlang, version: "26.2.5.19"            # stay on OTP 26 (omnibus-software defaults to 29)
override :ruby, version: "3.1.7", openssl_gem: '3.2.0'  # stay on Ruby 3.1.x (omnibus-software defaults to 3.4)
# nokogiri 1.19+ requires Ruby >= 3.2; pin to the latest 1.18.x (ruby >= 3.1.0)
# until the Ruby bump. omnibus-software defaults to 1.19.4.
override :nokogiri, version: "1.18.10"

# Embedded Chef Infra build — must match the chef gem in src/chef-server-ctl
# (18.10.17); omnibus-software's :chef default floats to the latest cinc branch.
override :chef, version: "stable/cinc-v18.10.17"

# FIPS-validated OpenSSL pin (omnibus-software defaults to 3.6.3, no FIPS):
override :openssl, version: "3.2.6", fips_version: "3.1.2", fips_enabled: true

# redis kept pinned (major 5 -> 8 jump deferred pending testing):
override :redis, version: "5.0.14"       # omnibus-software: 8.8.0 (major 5 -> 8) -- kept pinned
