require_relative 'lib/os_management'
Rock::OSManagement.activate_distribution_overrides

require_relative 'lib/package_set_overrides'
Rock::PackageSetOverrides.activate

