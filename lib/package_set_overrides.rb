module Rock
    class PackageSetOverrides
        def self.get_prefix()
            return "00_package_set_overrides-#{Autoproj.current_package_set.name}-"
        end

        # Cleanup all os specific symlinks in the overrides.d folder
        # of the given workspace
        def self.cleanup(ws: Autoproj.workspace)
            overridesd_dir = Rock::PackageSetOverrides::overridesd(ws: ws)
            return unless File.exists?(overridesd_dir)

            Dir.chdir(overridesd_dir) do
                Dir.glob("#{get_prefix()}*").each do |override_file|
                    puts
                    FileUtils.rm override_file
                end
            end
        end

        # Get the overrides folder of the buildconf in the active
        # autoproj workspace
        def self.overridesd(ws: Autoproj.workspace)
            return File.join(ws.root_dir, "autoproj","overrides.d")
        end

        # Activate the overrides for a workspace, where the override files
        # have to be in the <distribution_name>/<version> subfolder of the
        # current or given package set
        #
        # This must be able to run in parallel with another autoproj process,
        # potentially running the same code, for creating the same outcome, or
        # "just" reading the override files.
        def self.activate(ws: Autoproj.workspace, pkg_set_dir: File.dirname(caller_locations.first.path))
            overridesd_dir = Rock::PackageSetOverrides::overridesd(ws: ws)

            # The to-be-applied changes are collected in the file_changes hash.
            # the symbol :remove marks entries to be removed, otherwise,
            # a string target for a symlink is assumed.
            file_changes = {}
            # Fill file_changes with any already existing file,
            # marked for removal.
            if File.exists?(overridesd_dir)
                Dir.chdir(overridesd_dir) do
                    Dir.glob("#{get_prefix()}*").each do |override_file|
                        file_changes[override_file] = :remove
                    end
                end
            end

            overrides_dir = File.join(pkg_set_dir,"overrides")
            if File.exist?(overrides_dir)
                Autoproj.info "Package set override links from #{overrides_dir} added to buildconf"

                overridesd_dir = Rock::PackageSetOverrides::overridesd(ws: ws)
                if not File.exists?(overridesd_dir)
                    FileUtils.mkdir overridesd_dir
                end

                overrides_dir = File.absolute_path(overrides_dir)
                Dir.chdir(overridesd_dir) do
                    Dir.glob("#{overrides_dir}/*.yml").each do |override_file|
                        basename = File.basename(override_file)
                        file_changes["#{get_prefix()}#{basename}"] = override_file
                    end
                end
            end

            Dir.chdir(overridesd_dir) do
                file_changes.each do |override_file, target|
                    if target == :remove
                        FileUtils.rm override_file
                    else
                        # Create the symlink in a temporary file first, since
                        # it may involve removing of the old link.
                        # on linux, move is guaranteed to be atomic across processes,
                        # when on the same filesystem.
                        tmp_file = override_file + rand(10000).to_s
                        FileUtils.symlink(target, tmp_file, force:true)
                        begin
                            # Using File.rename here since FileUtils::mv checks if the
                            # symlink _targets_ are same and refuses the move even with
                            # force:true
                            File.rename(tmp_file, override_file)
                        rescue
                            FileUtils.rm(tmp_file)
                        end
                    end
                end
            end

            # Trigger reloading of local package set (autoproj/)
            # to include newly created files in overrides.d
            root_pkg_set = ws.manifest.main_package_set
            root_pkg_set.load_description_file
        end
    end
end
