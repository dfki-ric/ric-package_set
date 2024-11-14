require 'open3'

def upgrade_pip
    msg, status = Open3.capture2e("python -m pip install --user --upgrade pip")
    if status.success?
      Autoproj.debug "#{__FILE__}: pip has been upgraded to #{`pip --version`}"
    end
end

if !defined?(PIP_MIN_VERSION)
    PIP_MIN_VERSION=20
    pip_bin = ""
    ['pip','pip3'].each do |pip_name|
        pip_bin = `which #{pip_name}`.strip()
        break unless pip_bin.empty?
    end

    if not pip_bin.empty?
        msg, status = Open3.capture2e("#{pip_bin} --version")
        if status.success?
            msg =~ /pip ([0-9]+).* .*/
            major_version = $1
            if major_version.to_i < PIP_MIN_VERSION
                Autoproj.debug "#{__FILE__ }: current pip version (#{major_version}), min required is #{PIP_MIN_VERSION}, upgrading ..."
                upgrade_pip()
            end
        end
    end
end
