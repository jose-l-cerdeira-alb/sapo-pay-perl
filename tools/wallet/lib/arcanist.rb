class Arcanist

    def initialize(git)
        @git = git
    end

    def branch_is_accepted?(branch)
        branch = @git.current_branch()
        `arc feature | grep Accepted | grep #{branch}`
        return ($? == 0)
    end

end
