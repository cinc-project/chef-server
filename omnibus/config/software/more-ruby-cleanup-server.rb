#
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
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

name "more-ruby-cleanup-server"

skip_transitive_dependency_licensing true
license :project_license

source path: "#{project.files_path}/#{name}"

dependency "ruby"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  block "Delete bundler git cache, docs, and build info" do
    gemdir = File.expand_path("#{install_dir}/embedded/service/gem/ruby/*/")

    remove_directory "#{gemdir}/cache"
    remove_directory "#{gemdir}/doc"
    remove_directory "#{gemdir}/build_info"
  end

  # Remove CI workflow files and vendored dev lockfiles shipped inside gem
  # source trees. Neither is used at runtime, but the CVE scanner parses them:
  # the .github workflows pin GitHub Actions (flagged as step-security/
  # harden-runner CVEs), and the vendored Gemfile.locks make syft report their
  # dev-time pins (activesupport 7.0.3.1, rexml 3.2.5, addressable 2.8.0,
  # concurrent-ruby 1.1.10, ...) as if those gems were installed. Prune both
  # from every embedded gem tree.
  block "Prune gem CI workflows and vendored dev lockfiles" do
    require "fileutils"
    %w{service/gem/ruby lib/ruby/gems}.each do |tree|
      Dir.glob(File.expand_path("#{install_dir}/embedded/#{tree}/*/gems/*/.github")).each do |d|
        FileUtils.rm_rf(d)
      end
      Dir.glob(File.expand_path("#{install_dir}/embedded/#{tree}/*/gems/*/**/Gemfile.lock")).each do |f|
        FileUtils.rm_f(f)
      end
    end
  end

  # net-imap 0.2.4 is a *bundled* gem of Ruby 3.1.7 (uninstallable, unlike a
  # frozen default gem), unused by chef-server (the services carry their own
  # newer net-imap), with several CVEs fixed only in later lines. Replace the
  # interpreter copy with 0.5.15 -- the last release supporting Ruby 3.1.
  gem "uninstall net-imap --all --executables --ignore-dependencies", env: env
  gem "install net-imap --version 0.5.15 --no-document", env: env
end
