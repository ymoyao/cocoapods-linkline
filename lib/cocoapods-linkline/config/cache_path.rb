module BB
    class Cache
        def initialize(stable_source = nil)
            if stable_source.nil?
                stable_source = "https://git.babybus.co/babybus/ios/Specs/stable-specs.git"
            end
            @stable_source = stable_source
        end

        def cachePath()
            File.join(File.expand_path('~/.cache'), 'cocoapods-linkline','stable',@stable_source.split('/').last.chomp('.git').to_s)
        end
    end
end