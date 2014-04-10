module NodeJS
  class Helper
    attr_reader :node

    def initialize(node)
      @node = node
    end

    def build_environment
      case node['platform_family']
        when 'smartos'
          {
            'CPPFLAGS' => '-I/opt/local/include -I/usr/include -I/opt/local/include/gettext',
            'CFLAGS' => '-O -O2 -I/opt/local/include -I/usr/include -I/opt/local/include/gettext',
            'LDFLAGS' => '-L/opt/local/lib -Wl,-R/opt/local/lib -L/usr/lib/amd64 -Wl,-R/usr/lib/amd64'
          }
        else
          {}
      end
    end
  end
end
