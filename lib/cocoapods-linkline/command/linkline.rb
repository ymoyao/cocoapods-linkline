require 'cocoapods'
require 'cocoapods/user_interface'

class Pod::Installer::Analyzer
    alias_method :ll_original_generate_pod_targets, :generate_pod_targets
    def generate_pod_targets(resolver_specs_by_target, target_inspections)
        targets = ll_original_generate_pod_targets(resolver_specs_by_target, target_inspections)
        targets.each { |target|
            ll_rebuild_linkage(target,target,nil)
        }
        targets
    end

    def ll_rebuild_linkage(pod_target,root_pod_target,build_type) 
        ll_linkage,is_linkage_all = ll_fetch_linkage_from(pod_target)
        if ll_linkage
            build_type = ll_create_build_type_from(pod_target,ll_linkage)
            is_need_rewrite = ll_is_need_rewrite_build_type(pod_target,ll_linkage)
            pod_target.ll_rewrite_build_type(build_type) if is_need_rewrite
            ll_rebuild_linkage_in_dependencies(pod_target,root_pod_target,build_type) if is_linkage_all
        end           
    end

    def ll_rebuild_linkage_in_dependencies(pod_target,root_pod_target,build_type) 
        return if pod_target.dependencies.empty?
        pod_target.dependent_targets.each { |sub_pod_target|
            ll_rebuild_linkage_sub(sub_pod_target,root_pod_target,build_type)        
        }
    end

    def ll_rebuild_linkage_sub(pod_target,root_pod_target,build_type) 
        exit -9090 if !build_type
        ll_linkage,a = ll_fetch_linkage_from(pod_target)
        if ll_linkage && ll_linkage != build_type.linkage
            err_msg = "- Error: [#{pod_target.pod_name}] is define :linkage => #{ll_linkage} confict to it's parent [#{root_pod_target.pod_name}] :linkage => #{build_type}"
            # raise Informative, err_msg
            Pod::UI.puts "#{err_msg}".send(:red)
            exit -9090
        else
            is_need_rewrite = ll_is_need_rewrite_build_type(pod_target,build_type.linkage)
            pod_target.ll_rewrite_build_type(build_type) if is_need_rewrite
            ll_rebuild_linkage_in_dependencies(pod_target,root_pod_target,build_type)
        end   
    end

    def ll_fetch_linkage_from(pod_target)
        linkage = pod_target.target_definitions.map { |t| t.ll_linkages(false)[pod_target.pod_name] }.compact.first
        is_linkage_all = false
        if !linkage 
            linkage = pod_target.target_definitions.map { |t| t.ll_linkages(true)[pod_target.pod_name] }.compact.first
            is_linkage_all = true if linkage
        end
        [linkage,is_linkage_all]
    end

    def ll_create_build_type_from(pod_target,linkage)
        return nil if !linkage
        if pod_target.build_as_framework?
            Pod::BuildType.new(:linkage => linkage, :packaging => :framework)
        else
            Pod::BuildType.new(:linkage => linkage, :packaging => :library)
        end
    end

    def ll_is_need_rewrite_build_type(pod_target,linkage)
        ((linkage == :static && pod_target.build_as_dynamic?) || (linkage == :dynamic && pod_target.build_as_static?))
    end
end