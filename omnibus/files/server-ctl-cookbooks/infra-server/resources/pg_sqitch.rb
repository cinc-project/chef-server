#
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

provides :pg_sqitch

property :database,       String, required: true
property :username,       String
property :password,       String, required: false, default: ''
property :target_version, String
property :hostname,       String, required: true
property :port,           Integer, required: true
property :sslmode,        String, required: false, default: 'disable'

action :deploy do
  # sqitch 1.6.1: engine comes from the db:pg:// URI scheme; --to-change replaces
  # the removed --to-target. If target_version names a TAG it must be @-prefixed
  # (e.g. @2.4.0); change names are passed bare. This matches the pre-1.6.1 contract.
  target = new_resource.target_version ? "--to-change #{new_resource.target_version}" : ''
  # Password is supplied via PGPASSWORD env (below), never in the URI.
  db_uri = "db:pg://#{new_resource.username}@#{new_resource.hostname}:#{new_resource.port}/#{new_resource.database}"
  converge_by "Deploying schema from #{new_resource.name}" do
    execute "sqitch_deploy_#{new_resource.name}" do
      command <<-EOM.gsub(/\s+/, ' ').strip!
        sqitch --quiet
               --chdir #{new_resource.name}
               deploy #{db_uri} #{target} --verify
      EOM
      environment 'PERL5LIB' => "/opt/#{ChefUtils::Dist::Org::LEGACY_CONF_DIR}/embedded/lib", # force us to use omnibus perl
                  'LD_LIBRARY_PATH' => "/opt/#{ChefUtils::Dist::Org::LEGACY_CONF_DIR}/embedded/lib", # force us to use omnibus libraries
                  'PGPASSWORD' => new_resource.password,
                  'PGSSLMODE' => new_resource.sslmode

      # Sqitch 1.6.1 return codes for `deploy`:
      #   0 - changes applied, OR nothing to deploy (up-to-date)
      #       NOTE: sqitch 0.x returned 1 for "no changes"; 1.6.1 returns 0.
      #   2 - any error (option/usage, connection, deploy/verify failure).
      # `1` is retained below only for 0.x cross-version safety; 1.6.1 deploy never emits it.
      returns [0, 1]
    end
  end
end
