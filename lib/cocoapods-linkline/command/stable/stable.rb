module Pod

    # class StableOptions
    #   # define business specs,defalut is stable_specs
    #   option :business_specs, "stable_specs"

    #   # define custom lockSpecs tag
    #   option :tag, ""

    #   # define custom lockSpecs branch
    #   option :branch, ""
    # end

    class Command
      class Stable < Command
        require 'fileutils'
        require 'cocoapods/executable.rb'
        extend Executable
        executable :git

        ######################################## Env ########################################
        def env
          File.join(File.expand_path('~/.cache'), 'cocoapods-linkline','stable',@ll_stable_source.split('/').last.chomp('.git').to_s)
        end

        
        ######################################## Constant ########################################
        def ll_stable_specs_func_name
          "stable_specs" 
        end
        def ll_stable_specs_business_func_name 
          "stable_specs_business" 
        end
        def ll_stable_specs_local_func_name
          "stable_specs_lock" 
        end

        self.summary = 'a cocoapods plugin to fetch origin lock'
  

        ######################################## Main ########################################
        def run
          #1、first load source and origin lock name from podfile
          ll_load_stable

          #2、clone origin lock spec to cache dir 
          ll_cloneStable

          #3、fetch newest code
          git_reset
          git_pull

          local = ll_fetch_local_stable_datas
          origin = ll_fetch_origin_stable_datas
          #4、show origin_stable_lock diff with local_stable_lock
          ll_show_lock_diff(local, origin)

          #5、rewirte local_stable_lock with origin_stable_lock
          ll_rewirte_stable_lock(origin)
        end

  
        private
        ######################################## API ########################################
        def ll_load_stable
          unless File.exist?(File.join(Pathname.pwd, "Podfile"))
            err_msg = "- Error: #{File.join(Pathname.pwd, "Podfile")} is not exit"
            Pod::UI.puts "#{err_msg}".send(:red)
            exit -9001
          end
          
          matches = File.read(File.join(Pathname.pwd, "Podfile")).match(/^\s*stable!\s*'([^']+)'(?:,\s*(\w+):\s*'([^']+)')*/m)
          unless matches
            err_msg = "- Error: not stable define in the podfile! you can define like【stable 'https://git.babybus.co/babybus/ios/Specs/stable-specs.git', specs:'global_stable_specs'】in podfile"
            Pod::UI.puts "#{err_msg}".send(:red)
            exit -9002
          end

          eval(matches.to_s)
        end

        def ll_cloneStable
          unless Dir.exist?(File.join(env))
            clonePath = File.dirname(env)
            FileUtils.mkdir_p clonePath
            git_clone(@ll_stable_source,clonePath)
          end
        end

        def ll_fetch_local_stable_datas
          ll_create_stable_lock_template_if_need
          eval(ll_stable_specs_local_func_name)
        end

        def ll_fetch_origin_stable_datas
          unless File.exist?(File.join(env, "#{@ll_stable_file}.rb"))
            err_msg = "- Error: #{@ll_stable_file}.rb is not exit in #{@ll_stable_source}"
            Pod::UI.puts "#{err_msg}".send(:red)
            exit -9003
          end

          require File.join(env, "#{@ll_stable_file}.rb")

          if @ll_stable_file == ll_stable_specs_func_name #兼容默认只使用公共仓库锁的情况
            unless defined?(stable_specs)
              err_msg = "- Error: #{ll_stable_specs_func_name} function is not exit in #{@ll_stable_file}.rb"
              Pod::UI.puts "#{err_msg}".send(:red)
              exit -9004
            end
            eval(ll_stable_specs_func_name)
          else        
            unless defined?(stable_specs_business)
              err_msg = "- Error: #{ll_stable_specs_business_func_name} function is not exit in #{@ll_stable_file}.rb"
              Pod::UI.puts "#{err_msg}".send(:red)
              exit -9005
            end
            eval(ll_stable_specs_business_func_name)
          end   
        end

        def ll_show_lock_diff(local_arr, origin_arr)
          added, updated, rollbacked, deleted = ll_compare_specs(local_arr, origin_arr)

          #31m: 红色 32m:绿色 33m:黄色 34m:蓝色
          #puts "\e[34m#{string}\e[0m"
          if added.any?
            puts "\n新增了以下项目:".send(:green)
            puts added.join("\n")
          end

          if updated.any?
            puts "\n更新了以下项目:". send(:yellow)
            puts updated.join("\n")
          end

          if rollbacked.any?
            puts "\n回滚了以下项目:".send(:red)
            puts rollbacked.join("\n")
          end

          if deleted.any?
            puts "\n移除了以下项目:".send(:red)
            puts deleted.join("\n")
          end

          unless added.any? || updated.any? || added.any? || deleted.any?
            puts "\n已经是最新版本".send(:green)
          end
        end

        def ll_rewirte_stable_lock(stable_lock_origin_arr)
            File.open("#{ll_stable_specs_local_func_name}.rb", 'w') do |file|
              file.puts "def #{ll_stable_specs_local_func_name}"
              file.puts "["
              stable_lock_origin_arr.each_with_index do |spec, index|
                if index == stable_lock_origin_arr.length - 1
                  file.puts "  #{spec.inspect}"
                else
                  file.puts "  #{spec.inspect},"
                end
              end
              file.puts "]"
              file.puts "end"
            end          
        end

        def ll_create_stable_lock_template_if_need
          lockfilePath = File.join(Pathname.pwd,"#{ll_stable_specs_local_func_name}.rb")
          require lockfilePath if File.exist?(lockfilePath)
          unless File.exist?(lockfilePath) && defined?(stable_specs_lock)#判断方法是否存在只能使用 固定字符，不能通过变量间接判断
              Dir.chdir(Pathname.pwd) {
                File.open("#{ll_stable_specs_local_func_name}.rb", 'w') do |file|
                  file.puts "def #{ll_stable_specs_local_func_name}"
                  file.puts "["
                  file.puts "]"
                  file.puts "end"
                end
              }
          end
        end


        ######################################## Help ########################################
        # compare tags (>=)
        def versionGreatOrEqual(tag1, tag2)
          tags1 = tag1.split(".")
          tags2 = tag2.split(".")
        
          # Fill in the missing bits so that both tags have the same number of bits
          max_length = [tags1.length, tags2.length].max
          tags1 += ["0"] * (max_length - tags1.length)
          tags2 += ["0"] * (max_length - tags2.length)
        
          # Compare labels one by one from high to low
          (0...max_length).each do |i|
            if tags1[i].to_i > tags2[i].to_i
              return true
            elsif tags1[i].to_i < tags2[i].to_i
              return false
            end
          end
        
          # If all digits are equal, the labels are considered equal
          return true
        end

        # compare tags （>）
        def versionGreat(tag1, tag2)
          result = versionGreatOrEqual(tag1,tag2)
          if result == true && tag1 == tag2
            return false
          end
          return result
        end

        # compare specs
        def ll_compare_specs(specs_1, specs_2)
          added_projects = []
          updated_projects = []
          rollbacked_projects = []
          deleted_projects = []
        
          specs_2.each do |project_2|
            project_name_2, version_2 = project_2
            matching_project_1 = specs_1.find { |project_1| project_1[0] == project_name_2 }
        
            if matching_project_1.nil?
              added_projects << "【#{project_name_2}】 (#{version_2.to_s.send(:green)})"
            elsif matching_project_1[1] != version_2
              if versionGreat(version_2,matching_project_1[1])
                updated_projects << "【#{project_name_2}】 (#{matching_project_1[1]}) -> (#{version_2.to_s.send(:yellow)})"
              else
                rollbacked_projects << "【#{project_name_2}】 (#{version_2.to_s.send(:red)}) <- (#{matching_project_1[1]})"
              end
            end
            specs_1.delete(matching_project_1) if matching_project_1
          end

          #处理远端删除某个锁的情况
          specs_1.each do |project_1|
            project_name_1, version_1 = project_1
            deleted_projects << "【#{project_name_1}】 (#{"delete".send(:red)}) <- (#{version_1})"
          end unless specs_1.empty?
          return added_projects, updated_projects, rollbacked_projects, deleted_projects
        end

        #help load podfile option
        def stable!(source, options = {})
          @ll_stable_source = source
          if options.has_key?(:specs) 
            @ll_stable_file = options[:specs] 
          else
            @ll_stable_file = ll_stable_specs_func_name
          end
          @ll_stable_tag = options[:tag] if options.has_key?(:tag) 
          @ll_stable_branch = options[:branch] if options.has_key?(:branch) 
        end


        ######################################## Git Command  ########################################
        def git(*args)
         Dir.chdir(File.join(env)) { 
          return git! args 
        }
        end

        def git_reset 
          git('reset','--hard') #fommate git command
        end

        def git_pull 
           git('pull','origin','main','-f') #fommate git command
        end

        def git_clone(source, path)
            UI.section("Cloning `#{source}` into `#{path}`.") do
              Dir.chdir(path) { git! ['clone', source] } #origin git command
            end
        end
      end
    end
  end