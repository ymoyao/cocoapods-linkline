require 'cocoapods'
require 'cocoapods-core'

module Pod 
    class Podfile
        class TargetDefinition

            # linklines is a array to save data if you directy define :linkage => static or :linkage => dynimic
            def ll_expedition_linkages(name, requirements,key)
                linklines ||= {}
                options = requirements.last || {}
                linklines[Specification.root_name(name)] = options[key] if options.is_a?(Hash) && options[key]
                options.delete(key) if options.is_a?(Hash)
                requirements.pop if options.empty?
                linklines
            end

            def ll_linkages(is_linkage_all)
                pod_linkage = (is_linkage_all == true ? @linkages : @linkage) || {}
                pod_linkage.merge!(parent.ll_linkages(is_linkage_all)) { |key, v1, v2| v1 } if !parent.nil? && parent.is_a?(TargetDefinition)
                pod_linkage
            end

            original_parse_inhibit_warnings = instance_method(:parse_inhibit_warnings)
            define_method(:parse_inhibit_warnings) do |name, requirements|
                @linkage ||= {}
                @linkages ||= {}
                @linkage = @linkage.merge(ll_expedition_linkages(name, requirements,:linkage))
                @linkages = @linkages.merge(ll_expedition_linkages(name, requirements,:linkages))
                original_parse_inhibit_warnings.bind(self).call(name, requirements)
            end
        end
    end
end