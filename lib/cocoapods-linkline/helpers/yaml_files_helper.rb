require 'yaml'

YAML_CONFIG_LIST_KEY = "list"
YAML_CONFIG_REMOVE_KEY = "remove"
YAML_CONFIG_DEPENDENCIES_KEY = "dependencies"


# 数据源格式 json:{list:{name:ver},remove:[name],dependencies:{name:[name]}}
# list 受版本控制数据
# remove 移除数据
# dependencies 依赖数据
module BB
    class YamlFilesHelper
        def self.save_stable_podlock(yml_path, pod_targets)
            yamlData = read_stable_lock_yaml(yml_path)
            # test data
            # yamlData[YAML_CONFIG_REMOVE_KEY] = ["AFNetworking"]
            # yamlData[YAML_CONFIG_DEPENDENCIES_KEY] = {"BBNativeContainer":["BBSchemeDispatcher","BBComponentServicesKit"]}
            if yamlData.is_a? Hash
                listdata = yamlData[YAML_CONFIG_LIST_KEY]
                removedata = yamlData[YAML_CONFIG_REMOVE_KEY]
                dependenciesdata = yamlData[YAML_CONFIG_DEPENDENCIES_KEY]
            else 
                yamlData = {}
            end
            if listdata.nil?
                listdata = {}
            end
            if removedata.nil?
                removedata = []
            end
            if dependenciesdata.nil?
                dependenciesdata = {}
            end
            pod_targets.map { |pod_target|
                name = pod_target.pod_name
                listdata[name] = pod_target.root_spec.version.version
                # 策略：列表存在数据需要删除移除数据
                removedata.delete(name)
            }
            yamlData[YAML_CONFIG_LIST_KEY] = listdata
            yamlData[YAML_CONFIG_REMOVE_KEY] = removedata
            yamlData[YAML_CONFIG_DEPENDENCIES_KEY] = dependenciesdata
            save_stable_lock_yaml(yml_path, yamlData)
        end

        def self.save_stable_lock_yaml(yml_path, pod_jsondata)
            File.open(yml_path,"w") { |f| YAML.dump(pod_jsondata, f) }
        end

        def self.read_stable_lock_yaml(yml_path)
            if File.file?(yml_path)
                # puts "read yaml path:#{yml_path}"
                json = YAML.load_file(yml_path)
                # puts "read json:#{json}"
                return json
            end
            return {}
        end
    end
end