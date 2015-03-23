require "ubuntu_unused_kernels/version"
require "open3"

module UbuntuUnusedKernels
  PACKAGE_PREFIXES = %w{linux-image linux-headers}
  KERNEL_VERSION = %r{\d+\.\d+\.\d+-\d+}

  class << self
    def to_remove
      current, suffix = get_current
      packages = get_installed(suffix)

      PACKAGE_PREFIXES.each do |prefix|
        latest = packages.sort.select { |package|
          package =~ /^#{prefix}-#{KERNEL_VERSION}-#{suffix}$/
        }.last

        packages.delete(latest)
        packages.delete("#{prefix}-#{current}-#{suffix}")
      end

      return packages
    end

    def get_current
      uname = Open3.capture2('uname', '-r')
      raise "Unable to determine current kernel" unless uname.last.success?

      match = uname.first.chomp.match(/^(#{KERNEL_VERSION})-[[:alpha:]]+$/)
      raise "Unable to determine current kernel" unless match

      return match[1]
    end

    def get_installed(suffix)
      if suffix.nil? or suffix.empty?
        raise "Suffix argument must not be empty or nil"
      end

      args = PACKAGE_PREFIXES.collect { |prefix|
        "#{prefix}-*-#{suffix}"
      }
      dpkg = Open3.capture2(
        'dpkg-query', '--show',
        '--showformat', '${Package}\n',
        *args
      )
      raise "Unable to get list of packages" unless dpkg.last.success?

      packages = dpkg.first.split("\n")
      raise "No kernel packages found for prefix" if packages.empty?

      return packages
    end
  end
end
