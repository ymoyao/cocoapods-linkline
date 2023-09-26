require 'cocoapods-linkline/helpers'

# 公共spec配置库
# 业务线公共spec配置库
# 本地spec配置库 = 公共spec+业务线spec合并数据
# 数据格式 json {key,val}
module BB
  class StableSpecs
    def readData(yml_path)
      return YamlFilesHelper.read_stable_lock_yaml(yml_path)
    end
    def writeData(yml_path, data)
      YamlFilesHelper.save_stable_lock_yaml(yml_path, data)  
    end
    # podfile 更新配置文件使用
    def update_stable_lock(yml_path, pod_targets)
      puts "更新ymal配置文件:#{yml_path}成功". send(:yellow)
      YamlFilesHelper.save_stable_podlock(yml_path, pod_targets)
    end
  end
end