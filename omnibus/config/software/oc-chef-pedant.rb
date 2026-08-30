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

name "oc-chef-pedant"
source path: "#{project.files_path}/../../oc-chef-pedant"

license "Apache-2.0"
license_file "LICENSE"

dependency "ruby"

safe_versions_source = File.expand_path("#{project.files_path}/server-ctl-cookbooks/infra-server/libraries/safe_versions.rb")

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # Stage the Gemfile's CVE floors next to it: the isolated project_dir the
  # `source path:` fetcher builds in cannot reach the cookbook copy.
  copy safe_versions_source, "#{project_dir}/safe_versions.rb"

  bundle "install --path=#{install_dir}/embedded/service/gem", env: env

  command "mkdir -p #{install_dir}/embedded/service/oc-chef-pedant"

  sync project_dir, "#{install_dir}/embedded/service/oc-chef-pedant/"
end
