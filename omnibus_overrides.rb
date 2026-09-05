#
# When updating this, check doc/FrequentTasks.md for checklists to ensure all
# the various usages are updated in lockstep
#
# Only deliberate pins remain here; every other component now falls through to
# the omnibus-software default (latest). Removed (now using omnibus-software
# defaults): omnibus-ctl, ohai, logrotate (3.22.0), libffi (3.6.0, >= the 3.4.7
# EL10 fix), runit (2.3.1), gecode (6.2.0, unchanged), perl (5.42.2),
# openresty (1.31.1.1), sqitch (1.6.1).
#
# The generic software definitions this repo used to carry locally (haproxy,
# openresty-lpeg, postgresql13, postgresql96-bin, libuuid, omnibus-ctl,
# opensearch, perl_pg_driver) now live in omnibus-software; only gpg-key and
# the chef-server components remain local.

# Platform runtimes — pinned to a specific major on purpose:
override :erlang, version: "26.2.5.21"            # stay on OTP 26 (omnibus-software defaults to 29)
override :ruby, version: "3.1.7", openssl_gem: '3.2.0'  # stay on Ruby 3.1.x (omnibus-software defaults to 3.4)
# nokogiri 1.19+ requires Ruby >= 3.2; pin to the latest 1.18.x (ruby >= 3.1.0)
# until the Ruby bump. omnibus-software defaults to 1.19.4.
override :nokogiri, version: "1.18.10"
# redis 6.0.0 requires Ruby >= 3.2; pin the last 5.x, which is what
# src/chef-server-ctl/Gemfile.lock resolves. omnibus-software defaults to 6.0.0.
override "redis-gem", version: "5.4.1"

# Embedded Chef Infra build — must match the chef gem in src/chef-server-ctl
# (18.10.17); omnibus-software's :chef default floats to the latest cinc branch.
# Cinc-server carries its own branch off stable/cinc-v18.10.17 so it can bump
# vulnerable transitive gems (rack, json, faraday, addressable, concurrent-ruby)
# in the lockfile without disturbing the upstream release branch.
override :chef, version: "stable/cinc-v18.10.17-cinc-server"

# FIPS-validated OpenSSL pin (omnibus-software defaults to 3.6.3, no FIPS).
# fips_version must match the source tree the openssl-fips-provider definition
# stages (3.0.9, the FIPS-validated module Cinc ships everywhere -- upstream's
# 3.1.2 lives in their private omnibus-software). The FIPS build itself is
# gated by OMNIBUS_FIPS_MODE in the build repo's CI, not by an override key.
override :openssl, version: "3.2.6", fips_version: "3.0.9"

# redis kept pinned (major 5 -> 8 jump deferred pending testing):
override :redis, version: "5.0.14"       # omnibus-software: 8.8.0 (major 5 -> 8) -- kept pinned

# haproxy stays on the 3.0 LTS line (omnibus-software defaults to the latest
# stable branch, 3.4.x):
override :haproxy, version: "3.0.25"

# opensearch stays on the final 1.x release until the OpenSearch major
# upgrade (omnibus-software defaults to 3.7.0, whose bundle layout differs):
override :opensearch, version: "1.3.20"
# OpenSearch 1.3.x calls System.setSecurityManager, which JDK 24+ always throws
# on (JEP 486); stay on the 17 line 15.10.114 shipped. omnibus-software: 25.0.4+7.
override "server-open-jre", version: "17.0.20+8"

# perl_pg_driver (DBD::Pg) must build against the embedded PostgreSQL 13,
# not omnibus-software's current-major postgresql definition:
override :perl_pg_driver, postgresql_dependency: "postgresql13"
