module Pod
    class Podfile
      module DSL
        def stable(source,spce_name)
            $ll_stable_source = source
            $ll_stable_lock_origin = spce_name
        end
      end
    end
end