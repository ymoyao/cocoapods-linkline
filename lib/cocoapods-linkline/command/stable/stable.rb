require 'cocoapods-linkline/config/source_manager'
require 'cocoapods-linkline/config/cache_path'
require 'cocoapods-linkline/helpers'

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

        self.summary = '拉取稳定lock配置'
        self.description = <<-DESC
          拉取稳定lock配置插件。利用版本比对进行更新配置实现对组件版本控制管理。
        DESC
        
        def initialize(argv)
          @help = argv.flag?('help')
          super
        end
        def validate!
          super
          banner! if @help
        end

        #help load podfile option
        def stable!(source, options = {})
          @ll_stable_source = source
          if options.has_key?(:specs) 
            @businessSpec = options[:specs]
            puts "业务源:#{@businessSpec}"
          end
          @ll_stable_tag = options[:tag] if options.has_key?(:tag) 
          @ll_stable_branch = options[:branch] if options.has_key?(:branch)

          @cache = BB::Cache.new(source)
          @source_manager = BB::SourceManager.new(@cache, @businessSpec)
          configGitPath(@cache.cachePath)
        end

        ######################################## Main ########################################
        
        def run
          #1、first load source and origin lock name from podfile
          ll_load_stable
          #2、clone origin lock spec to cache dir 
          ll_cloneStable
          #3、fetch newest code
          ll_fetch_stale_git
          
          # 4、数据合并
          @source_manager.merge_stable_data
        end

        private
        ######################################## API ########################################
        def ll_load_stable
          unless File.exist?(File.join(Pathname.pwd, "Podfile"))
            err_msg = "- Error: #{File.join(Pathname.pwd, "Podfile")} is not exit"
            Pod::UI.puts "#{err_msg}".send(:red)
            exit -9001
          end

          #获取podfile 内容
          #1、删除所有注释行，避免干扰
          #2、正则匹配，筛选出stable 方法
          #3、执行stable 方法，获取配置
          podfileContent = File.read(File.join(Pathname.pwd, "Podfile"))
          podfileContent_vaild = podfileContent.lines.reject { |line| line.strip.start_with?("#") }.join
          stableCommand = podfileContent_vaild.match(/^\s*stable!\s*'([^']+)'(?:,\s*(\w+):\s*'([^']+)')*/m)
          unless stableCommand
            err_msg = "- Error: not stable define in the podfile! you can define like【stable! 'https://git.babybus.co/babybus/ios/Specs/stable-specs.git', specs:'global_stable_specs'】in podfile"
            Pod::UI.puts "#{err_msg}".send(:red)
            exit -9002
          end
          eval(stableCommand.to_s)
        end

        def ll_cloneStable
          cachePath = @cache.cachePath
          unless Dir.exist?(File.join(cachePath))
            clonePath = File.dirname(cachePath)
            FileUtils.mkdir_p clonePath
            git_clone(@ll_stable_source,clonePath)
          end
        end

        def ll_fetch_stale_git
          git_reset
          git_fetch
          git_checkout_and_pull(@ll_stable_source, @ll_stable_branch, @ll_stable_tag)
        end

      end
    end
  end