
## FIPS Integration

This assumes you understand what the **FIPS 140-2** validation is. Putting the Chef Server into *FIPS mode* means:

1. nginx runs with `OPENSSL_CONF` pointing at `embedded/ssl/openssl.fips.cnf`, a strict config that loads only the
   FIPS and base providers with `default_properties = fips=yes` and fails if the FIPS provider can't load. erchef
   still gets `OPENSSL_FIPS=1`, which does nothing on OpenSSL 3. The embedded `openssl` and other tools use the
   default `openssl.cnf`, which activates the FIPS provider alongside the default and legacy ones.
2. Using the **erlang crypto** app it activates the FIPS module for any native calls.

The server can be switched into and out of FIPS mode at runtime. Edit the `chef-server.rb` config by adding `fips true` or `fips false` to force FIP mode as necessary. On systems where FIPS is enabled at the kernel level this config is defaulted to `true`. On all other systems it is defaulted to `false`. FIPS mode is supported on **RHEL** systems.

### FIPS Implementation Details

The erlang crypto app provides `crypto` module implementation. We no longer use the *erlang-crypto2* app.

- Setting `fips true` in `/etc/opscode/chef-server.rb` enables *FIPS* mode for Chef-Infra-Server.



