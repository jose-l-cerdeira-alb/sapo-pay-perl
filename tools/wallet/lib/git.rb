require 'git'

class GitLib

  def initialize()
    super()
    @git = Git.open(basedir())
  end

  def basedir()
	basedir = `git rev-parse --show-toplevel`.chomp
        if ($? != 0)
            exit 1
        end
	basedir
  end

  def current_branch()
    @git.current_branch
  end

  def switch_branch(branch)
    @git.checkout(branch)
  end

  def head()
	 return @git.object('HEAD^')
  end

  def status()

	 return @git.status
  end

  def clean?()
	@git.status.changed.size == 0
  end

  def create_from_remote(name,remote="origin/master")
      
        call = "git checkout -b "+name+" "+remote

	     `#{call}`.chomp
	
	     if ($? != 0)
            exit 1
       end
	
      return get_current_hash()
  end

  def get_current_hash()

    call = "git rev-parse HEAD";

    hash = `#{call}`.chomp

    return hash

  end


  def list_components(path)

      components = `find #{path} -name DEBIAN -type d`.chomp


      if components.empty? == true
        return []
      end

      return components.gsub!("DEBIAN","").split("\n")


  end


  def get_changed_components(path,commit)

      components = list_components(path)

      changed = Array.new

      components.each do |comp|

          cmd = "git diff --exit-code --quiet #{commit}..HEAD #{comp}"

          `#{cmd}`.chomp
          
          if ($?.exitstatus>0)
            changed.push(comp)
          end
          
      end

      return changed

  end

end
