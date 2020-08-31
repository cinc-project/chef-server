#
# When updating this, check doc/FrequentTasks.md for checklists to ensure all
# the various usages are updated in lockstep
#
override :erlang, version: "22.2"
override :'omnibus-ctl', version: "master"
override :chef, version: "v15.17.4"
override :ohai, version: "v15.12.0"
override :ruby, version: "2.6.7"
override :perl, version: "5.18.1"
override :nokogiri, version: "1.10.10" # if not pinned it forces the entire stack to rebuild

override :openresty, version: "1.19.3.1"
