name 'cleanup'
default_version '1.0.0'
skip_transitive_dependency_licensing true
license :project_license

build do
  # strip shared object files related to gecode installs
  # Use find to handle both Gecode 3.x (.so.32.0) and 6.x (.so.*) naming
  command "find #{install_dir}/embedded/lib -name 'libgecode*.so*' -exec strip {} +"

  # remove any test fixture pivotal keys to avoid user confusion
  command "find #{install_dir} -name pivotal.pem -delete"
end
