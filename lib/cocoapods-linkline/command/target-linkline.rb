require 'cocoapods'
require 'cocoapods/user_interface'
class Pod::Target
    #define a func to rewrite target build_type, the build_type property is private  
    def ll_rewrite_build_type(build_type) 
        Pod::UI.puts "#{name} rebuild :linkage => #{build_type}"
        @build_type = build_type
    end
end