module Pod
    class Podfile
      module DSL
        #a func define to avoid pod command error
        def stable!(source, options = {})
        end
      end
    end
end