module Pod
    class Installer
      class Xcode
        class TargetValidator

            alias_method :ll_verify_no_static_framework_transitive_dependencies, :verify_no_static_framework_transitive_dependencies
            def verify_no_static_framework_transitive_dependencies
                ll_verify_no_static_framework_transitive_dependencies if !$ll_no_check_static
            end
            
        end
      end
    end
end


# module Pod
#   class Command
#     class Install < Command
#       class << self

#         # extension --virtual optional
#         alias_method :ll_origin_options, :options
#         def options
#           [['--no-check-static', 'not check the binary for static links']].concat(ll_origin_options)
#         end

#       end

#       # remove virtual directly to avoid failed on valited
#       alias_method :ll_origin_initialize, :initialize
#       def initialize(argv)
#         $ll_no_check_static = argv.flag?('no-check-static',false)
#         ll_origin_initialize(argv)
#       end

#     end

#     class Update < Command
#       class << self

#         # extension --virtual optional
#         alias_method :ll_origin_options, :options
#         def options
#           [['--static', 'not check the binary for static links']].concat(ll_origin_options)
#         end

#       end

#       # remove virtual directly to avoid failed on valited
#       alias_method :ll_origin_initialize, :initialize
#       def initialize(argv)
#         $ll_no_check_static = argv.flag?('static',false)
#         ll_origin_initialize(argv)
#       end

#     end
#   end
# end

module Pod
    class Command
        class << self
  
          alias_method :ll_origin_options, :options
          def options
            [['--no_check_static_link', 'not check the binary for static links']].concat(ll_origin_options)
          end
  
        end
  
        # remove virtual directly to avoid failed on valited
        alias_method :ll_origin_initialize, :initialize
        def initialize(argv)
          ll_origin_initialize(argv)
          $ll_no_check_static = argv.flag?('no_check_static_link',false)
        end

      end
  end