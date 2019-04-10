
require 'thor'


class Component < Thor


		  def initialize(args=[], options={}, config={})
		    super(args, options, config)

		    @wallet = WalletLib.new( ConfigLib.new("/home/luissantos/.wallet/config.yml") )
		    

		  end

        desc "info", "Component info"
        def info(dir)

        end


        desc "create", "Creats a new component"
        def create(name)


			data = { "name" => name  }	
				 	
			File.open("./.component", "w") {|f| f.write(data.to_yaml) }

        end


        desc "changes", "changes"
        def changes(commit)

        	@wallet.get_commponent_path()
        end

        desc "build", "Build component packages"
        option :commit
        def build()

                if options[:commit]
                        commit = options[:commit]
                else
                        commit = nil
                end

                @wallet.recursive_build(commit)
        end




end


