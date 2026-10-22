# Cinc Server Release Notes

Cinc Server 15.x is built from Chef Infra Server. For changes that came from
upstream, see the [Chef Infra Server Release Notes](https://docs.chef.io/release_notes/server/).
This file lists what Cinc Server changes on top.

## 15.10.127

Based on Chef Infra Server 15.10.127. It carries Cinc fixes that Progress's
15.10.127 doesn't have, starting with the license fix below.

### Action required: set `from_email`

The default sender for the identity service's password-reset and
email-verification mail is now `"Cinc Server" <donotreply@example.com>`. It
used to be `"Opscode" <donotreply@chef.io>`, which claimed Chef's domain.
`example.com` is reserved and publishes a strict DMARC policy, so mail sent
from the default is refused by any mail server that enforces DMARC. Set an address in a domain
you control in `/etc/cinc-project/cinc-server.rb`:

```ruby
from_email '"Cinc Server" <cinc-server@your-domain.example>'
```

then run `cinc-server-ctl reconfigure`.

### Fixes

- The server no longer stops answering 90 days after install. Without a
  Progress license, Chef Infra Server 15.10.102 and later refuse every request
  with a 403 "license expired" once 90 days have passed; Cinc Server now
  reports a license that never expires and no longer runs the Chef Automate
  license command or reads `/tmp/lic`
  ([#48](https://gitlab.com/cinc-project/distribution/server/-/issues/48)).
- `knife ec backup` and `knife ec restore` now find the server's
  configuration under `/etc/cinc-project` instead of failing on Chef Server's
  `/etc/opscode` paths
  ([#26](https://gitlab.com/cinc-project/distribution/server/-/issues/26)).
- `notification_email` is no longer accepted as a working setting. Nothing
  ever read it; existing configurations that set it still load
  ([#33](https://gitlab.com/cinc-project/distribution/server/-/issues/33)).
- The identity service pages (`/id`) and its emails now carry Cinc Server
  branding instead of the Progress Chef logo, wording and legal links
  ([#24](https://gitlab.com/cinc-project/distribution/server/-/issues/24)).
- `cinc-server-ctl notice` no longer claims that OpenSearch and PostgreSQL are
  commercially licensed or that the server's own components are proprietary
  ([#42](https://gitlab.com/cinc-project/distribution/server/-/issues/42)).
