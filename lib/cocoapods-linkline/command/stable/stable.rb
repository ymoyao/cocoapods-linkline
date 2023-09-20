module Pod
    class Command
      class Stable < Command
        require 'fileutils'
        require 'cocoapods/executable.rb'
        extend Executable
        executable :git
  
        self.summary = 'a cocoapods plugin to fetch origin lock'

        def initialize(argv)
          super
        end
  
        def run
          #1、first create stable_lock.rb if no exit, and input a template function for the podfile
          ll_create_stable_lock_template

          #2、load podfile to fetch ll_stable_source and ll_stable_lock_origin
          verify_podfile_exists!

          #3、clone module to cache dir 
          ll_cloneStable

          #4、fetch newest code
          git_reset
          git_pull

          require File.join(Pathname.pwd,"#{ll_stable_lock}.rb")
          require File.join(env, "#{$ll_stable_lock_origin}.rb")
          stable_lock_arr = eval("#{ll_stable_lock}")
          stable_lock_origin_arr =  eval("#{$ll_stable_lock_origin}")
          #5、show origin_stable_lock diff with local_stable_lock
          ll_show_lock_diff(stable_lock_arr, stable_lock_origin_arr)

          #6、rewirte local_stable_lock with origin_stable_lock
          ll_rewirte_stable_lock(stable_lock_origin_arr)
        end
  
        private
        # API
        def ll_cloneStable
          unless Dir.exist?(File.join(env))
            clonePath = File.dirname(env)
            FileUtils.mkdir_p clonePath
            git_clone($ll_stable_source,clonePath)
          end
        end

        def ll_show_lock_diff(stable_lock_arr, stable_lock_origin_arr)
          added, updated, rollbacked = ll_compare_specs(stable_lock_arr, stable_lock_origin_arr)

          #31m: 红色 32m:绿色 33m:黄色 34m:蓝色
          #puts "\e[34m#{string}\e[0m"
          if added.any?
            puts "\n新增了以下项目:".send(:green)
            puts added.join("\n")
          end

          if updated.any?
            puts "\n更新了以下项目:".send(:yellow)
            puts updated.join("\n")
          end

          if rollbacked.any?
            puts "\n回滚了以下项目:".send(:red)
            puts rollbacked.join("\n")
          end

          unless added.any? || updated.any? || added.any?
            puts "\n已经是最新版本".send(:green)
          end
        end

        def ll_rewirte_stable_lock(stable_lock_origin_arr)
            File.open("#{ll_stable_lock}.rb", 'w') do |file|
              file.puts "def #{ll_stable_lock}"
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

        def ll_compare_specs(specs_1, specs_2)
          added_projects = []
          updated_projects = []
          rollbacked_projects = []
        
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
          end
        
          return added_projects, updated_projects, rollbacked_projects
        end

        def ll_create_stable_lock_template
          unless File.exist?(File.join(Pathname.pwd,"#{ll_stable_lock}.rb"))
            Dir.chdir(Pathname.pwd) {
              File.open("#{ll_stable_lock}.rb", 'w') do |file|
                file.puts "def #{ll_stable_lock}"
                file.puts "["
                file.puts "]"
                file.puts "end"
              end
            }
          end
        end

        #####help
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

        ##### constant
        def ll_stable_lock
          "stable_lock"
        end

        ##### env
        def env
            File.join(File.expand_path('~/.cache'), 'cocoapods-linkline','stable',$ll_stable_source.split('/').last.chomp('.git').to_s)
        end

        def ll_stable_lock_fold
          File.dirname(Pod::Config.instance.podfile_path)
        end

        ##### git command 
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