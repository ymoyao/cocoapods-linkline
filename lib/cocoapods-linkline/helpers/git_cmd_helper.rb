# cache stable

######################################## Git Command  ########################################
def configGitPath(gitPath)
    @gitPath = gitPath
end

def git_cmd(*args)
    Dir.chdir(File.join(@gitPath)) { 
     return git! args 
   }
end

def git_reset
    git_cmd('reset','--hard') #fommate git command
end

def git_fetch 
    git_cmd('fetch') #fommate git command
end

def git_checkout_and_pull(stable_source, stable_branch = nil, stable_tag = nil)
    # puts "spec source:#{stable_source} branch:#{stable_branch} tag:#{stable_tag}"
    if stable_branch || stable_tag 
        if stable_branch
            unless git_branch_exists?(stable_branch)
                err_msg = "- Error: #{stable_source} did not exit branch #{stable_branch}"
                Pod::UI.puts "#{err_msg}".send(:red)
                exit -9006
            end
            git_cmd('checkout',stable_branch) #fommate git command
            git_cmd('reset','--hard',"origin/#{stable_branch}") #fommate git command
        end
        if stable_tag
            unless git_tag_exists?(stable_tag)
                err_msg = "- Error: #{stable_source} did not exit tag #{stable_tag}"
                Pod::UI.puts "#{err_msg}".send(:red)
                exit -9007
            end
    
            git_cmd('checkout',stable_tag) #fommate git command
        end
    else
        protechBranch = git_cmd('symbolic-ref','refs/remotes/origin/HEAD').split("/").last.strip || "main"
        git_cmd('checkout',protechBranch)
        git_cmd('reset','--hard',"origin/#{protechBranch}") #fommate git command
    end
end

def git_tag_exists?(tag)
    if tag
        git_cmd('tag').split("\n").include?(tag)
    end
    return true
end

def git_branch_exists?(branch)
    if branch
        branchs = git_cmd('branch','-a').split("\n")
        branchs.include?(branch) || branchs.include?('  remotes/origin/' + branch) || branchs.include?('remotes/origin/' + branch)
    end
    return true
end

def git_clone(source, path)
    UI.section("Cloning `#{source}` into `#{path}`.") do
        Dir.chdir(path) { git! ['clone', source] } #origin git command
    end
end