module Pod
    class Installer

      # extension new option :skip_verify_static_framework, defalut false
      class InstallationOptions
        # Whether to skip verify dynimic framework linked static frameworks. defalut is verify
        option :skip_verify_static_framework, false

        # Whether to disable linkline framework on debug config
        option :disable_linkline_on_debug, false
      end

      class Xcode
        class TargetValidator

            alias_method :ll_verify_no_static_framework_transitive_dependencies, :verify_no_static_framework_transitive_dependencies
            def verify_no_static_framework_transitive_dependencies
              # if skip_verify_static_framework is true, skip verify!
              ll_verify_no_static_framework_transitive_dependencies unless installation_options.skip_verify_static_framework?
            end
            
        end
      end
    end
end