require_relative './git'
require_relative './trac/tickets'
require_relative './trac/milestones'

class WalletLib

  def initialize(config)
    super()

    @config = config
    @git = GitLib.new
    @tickets = TracLib::Tickets.new(
        @config.get("trac.url"),
        @config.get("trac.username"),
        @config.get("trac.password"))

     @milestones = TracLib::Milestones.new(
        @config.get("trac.url"),
        @config.get("trac.username"),
        @config.get("trac.password"))
  end

  def release()

    basedir = @git.basedir()

    release_file = File.open(basedir + "/release")
    release = release_file.read().chomp
    release_file.close

    return release
  end

  def open_ticket(number,name,origin="origin/develop")
    branch_name ="ticket/#{number}_#{name}"

    ticket = @tickets.get_ticket(number)

    if ticket == nil
      print "ticket not found"
      return nil
    end

    #current_user = @tickets.get_current_user()

    #hashcommit = open_branch(branch_name,origin)

    #comment = "Branch \"#{branch_name}\" opened from #{origin} (#{hashcommit})"
    
    #@tickets.change_owner(number,comment,current_user)

    #pp @tickets.get_actions(number)
    pp @milestones.get_all_milestones()
    
    #get_ticket
    #ask yes/no
    #create branch
  end

  def open_feature(name)

    branch_name ="features/#{name}"

  end

  def open_hotfix(release,number)
    branch_name ="hotfix/#{release}-#{number}"
  end

  def open_other()

  end

  def print_tickets(query)
  	result = @tickets.find_ticket(query)

	
	result.each do |ticket| 
	       print "* http://trac.intra.sapo.pt/walletfeedback/ticket/#{ticket}\n"
	end

  end

  def open_branch(name,origin)
    commit_hash = @git.create_from_remote(name,origin)

  end

  def recursive_build(commit=nil)

    pwd = Dir.pwd

    if commit
      build_scripts = @git.get_changed_components(pwd,commit)
    else
      build_scripts = @git.list_components(pwd);
    end


    if (build_scripts.count < 1)
      print "Didn't find packages to build inside current directory.\n"
      return
    end

    packages_built = Array.new

    build_scripts.each do |folder|

      script = folder+"buildpackage"
      
      pkgname = `grep PACKAGE= #{script}`.chomp.match(/PACKAGE=(.*)/)[1]
      pkgdir = `dirname #{script}`.chomp
      Dir.chdir(pkgdir)
      print "Building #{pkgname} from #{pkgdir}\n"
      `./buildpackage > build.log 2>&1`
      if ($? == 0)
        debfile = `grep dpkg-deb: #{Dir.pwd}/build.log`.chomp.match(/[^\/]+\.deb/)[0]
        print "Finished building '#{debfile}'.\n"
        packages_built.push(debfile)
      else
        print "Build failed. See details on #{Dir.pwd}/build.log\n"
      end
      Dir.chdir(pwd)
      packages_built
    end
  end

  def get_changed_components(commit)

      base = @git.basedir()

      pp @git.get_changed_components(base,commit)

  end


  def get_all_components()

      base = @git.basedir()

      @git.list_components(base)
  end

end
