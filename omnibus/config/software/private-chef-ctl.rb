#
# Copyright 2012-2014 Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name "chef-server-ctl"

source path: "#{project.files_path}/../../src/chef-server-ctl"

license :project_license
skip_transitive_dependency_licensing true

dependency "postgresql13" # for libpq
dependency "omnibus-ctl"
# for the cinc-wrapper binstub the link steps below point at
dependency "chef"

safe_versions_source = File.expand_path("#{project.files_path}/server-ctl-cookbooks/infra-server/libraries/safe_versions.rb")

build do

  env = with_standard_compiler_flags(with_embedded_path)

  # Stage the Gemfile's CVE floors next to it: the isolated project_dir the
  # `source path:` fetcher builds in cannot reach the cookbook copy.
  copy safe_versions_source, "#{project_dir}/safe_versions.rb"

  # we would like to do this 'bundle config set --local without development' but appbundler is insisting
  # on installing
  bundle "install", env: env

  gem "build chef-server-ctl.gemspec", env: env

  # Hack: install binaries in /tmp because we don't actually want them at all
  gem "install chef-server-ctl-*.gem --no-document --verbose --bindir=/tmp", env: env

  appbundle "chef-server-ctl", env: env

  link "#{install_dir}/bin/cinc-server-ctl", "#{install_dir}/bin/private-cinc-ctl"

  # These are necessary until we remove all hardcoded references to embedded/bin/*-ctl
  link "#{install_dir}/bin/cinc-server-ctl", "#{install_dir}/embedded/bin/cinc-server-ctl"
  link "#{install_dir}/bin/cinc-server-ctl", "#{install_dir}/embedded/bin/private-cinc-ctl"

  # cinc-wrapper is the `chef` software definition's chef-bin binstub; it
  # re-execs $0 with "chef" swapped for "cinc" to reach cinc-server-ctl.
  %w(chef-server-ctl private-chef-ctl).each do |bin|
    link "#{install_dir}/bin/cinc-wrapper", "#{install_dir}/bin/#{bin}"
  end
end
