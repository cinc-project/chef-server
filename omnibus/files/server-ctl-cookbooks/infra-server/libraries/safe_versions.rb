# frozen_string_literal: true
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
##
# CVE floors the service Gemfiles read via resolve_safe_version, so bundler
# cannot resolve below them. Values are what upstream 15.10.125 locked against.
module SafeVersions
  MINIMUM_SAFE_RACK_VERSION = '3.2.5'

  MINIMUM_SAFE_REXML_VERSION = '3.4.2'

  # 0.5.15 is the last release supporting the pinned Ruby 3.1; let the floor
  # rise with the interpreter rather than hold a newer Ruby back at 0.5.x.
  NET_IMAP_FIX_VERSION = Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2') ? '0.6.0' : '0.5.15'
end
