require 'cocoapods-linkline/helpers'
require 'cocoapods-linkline/config/stable_specs'

# 数据源管理
module BB
    class SourceManager
        def initialize(cache = nil, businessSpecName = nil)
            if cache.nil? 
                @cache = BB::Cache.new()
            else
                @cache = cache
            end
            @businessSpecName = businessSpecName
        end

        # 仓库缓存目录
        def cachePath
            return @cache.cachePath
        end

        # 公共源路径(远端)
        def public_stable_yaml
            return File.join(cachePath, "stable_specs.yml") #名称固定
        end

        # 业务源路径(远端)
        def business_stable_yaml
            if @businessSpecName
                return File.join(cachePath, "#{@businessSpecName}.yml") #名称由各自业务线约定
            end
            return nil
        end

        # 本地源路径
        def local_stable_yaml
            return File.join(Pathname.pwd, "stable_specs_lock.yml") #名称固定
        end

        # podfile 更新配置文件使用(通用)
        def update_common_stable_lock(pod_targets)
            update_stable_lock(public_stable_yaml, pod_targets)
        end
        # podfile 更新配置文件使用(业务线)
        def update_business_stable_lock(businessSpecName, pod_targets)
            @businessSpecName = businessSpecName
            update_stable_lock(business_stable_yaml, pod_targets)
        end
        private def update_stable_lock(yml_path, pod_targets)
            stableSpec = BB::StableSpecs.new()
            stableSpec.update_stable_lock(yml_path, pod_targets)
        end

        # 产品线本地lock数据
        def fetch_local_stable_datas
            @localSpec = BB::StableSpecs.new()
            return @localSpec.readData(local_stable_yaml)
        end

        # 远端公共lock数据
        def fetch_origin_stable_datas
            # 策略：公共数据包含通用数据 + 业务线数据
            pubSpec = BB::StableSpecs.new()
            common_data = pubSpec.readData(public_stable_yaml)
            # 业务线数据
            business_config_file = business_stable_yaml
            if business_config_file
                if File.exist?(business_config_file)
                    busimessSpec = BB::StableSpecs.new()
                    busimess_data = busimessSpec.readData(business_config_file)
                else
                    puts "业务线公共配置文件#{business_config_file}不存在，请确认!!!". send(:yellow)
                    exit
                end
            end
            if busimess_data
                # 数据合并操作（策略：业务线公共盖通用数据，理论不存在该情况）
                newData = common_data
                listdata = newData[YAML_CONFIG_LIST_KEY]
                removedata = newData[YAML_CONFIG_REMOVE_KEY]
                dependenciesdata = newData[YAML_CONFIG_DEPENDENCIES_KEY]
                busimess_data.each do | key, val|
                    if key == YAML_CONFIG_LIST_KEY
                        if val.is_a?(Hash)
                            val.each do |list_name,list_ver|
                                listdata[list_name] = list_ver
                            end
                        end
                    elsif key == YAML_CONFIG_REMOVE_KEY
                        if val.is_a?(Array)
                            val.each do |remove_name|
                                removedata.push(remove_name)
                            end
                        end
                    elsif key == YAML_CONFIG_DEPENDENCIES_KEY
                        if val.is_a?(Hash)
                            val.each do |dependencies_name,dependencies_val|
                                dependenciesdata[dependencies_name] = dependencies_val
                            end
                        end
                    end
                end
                return newData
            end
            return common_data
        end

        # 更新本地lock数据
        def update_localstable_datas(stable_lock)
            @localSpec.writeData(local_stable_yaml, stable_lock)  
        end

        # 合并stable数据
        def merge_stable_data()
            #4、show origin_stable_lock diff with local_stable_lock
            new_stable_spec = compare_specs(fetch_local_stable_datas, fetch_origin_stable_datas)

            #5、rewirte local_stable_lock with origin_stable_lock
            update_localstable_datas(new_stable_spec)    
        end
  
        ######################################## Help ########################################
        # compare tags (>=)
        def versionGreatOrEqual(tag1, tag2)
            if tag1.to_i >= tag2.to_i
                return true
            else
                return false
            end
            return true
        end

        # compare tags （>）
        def versionGreat(tag1, tag2)
            result = versionGreatOrEqual(tag1,tag2)
            if result == true && tag1 == tag2
                return false
            end
            return result
        end

        # compare specs 参数1:本地，参数2:远端
        def compare_specs(local_specs, common_specs)
            added_projects = []
            updated_projects = []
            rollbacked_projects = []
            deleted_projects = []
            new_specs = local_specs

            listdata = common_specs[YAML_CONFIG_LIST_KEY]
            removedata = common_specs[YAML_CONFIG_REMOVE_KEY]
            dependenciesdata = common_specs[YAML_CONFIG_DEPENDENCIES_KEY]

            # puts "local_specs:#{local_specs}".send(:green)
            # puts "common_specs:#{common_specs}".send(:green)
            # step.1 匹配组件版本信息
            listdata.each do |name, version|
                name = name.to_s
                local_version = local_specs[name]
                if local_version.nil?
                    # 本地不存在这个数据
                elsif local_version != version
                    # 版本不一致
                    if versionGreat(version, local_version)
                        updated_projects << "【#{name}】 (#{local_version}) -> (#{version.to_s.send(:yellow)})"
                    else
                        rollbacked_projects << "【#{name}】 (#{version.to_s.send(:red)}) <- (#{local_version})"
                    end
                    new_specs[name] = version
                end
            end
            # step.2 匹配组件新增
            dependenciesdata.each do |name, array|
                name = name.to_s
                version = listdata[name]
                unless version
                    puts "公共库缺少[#{name}]版本依赖 cls:#{listdata.class} listdata:#{listdata}".send(:red)
                    exit
                end
                local_exist_ver = new_specs[name]
                if local_exist_ver.nil?
                    new_specs[name] = version
                    added_projects << "【#{name}】 (#{version.to_s.send(:green)})"
                end
                if array.is_a?(Array)
                    array.each do |name|
                        name = name.to_s
                        local_exist_ver = new_specs[name]
                        if local_exist_ver.nil?
                            new_specs[name] = version
                            added_projects << "【#{name}】 (#{version.to_s.send(:green)})"
                        end
                    end
                end
            end
            # step.3 匹配组件移除
            removedata.each do |name|
                name = name.to_s
                # local_exist_ver = new_specs[name]
                version = listdata[name]
                if version
                    deleted_projects << "【#{name}】 (#{"delete".send(:red)}) <- (#{version})"
                end
                new_specs.delete(name)
            end
            showMergeLog(added_projects, updated_projects, rollbacked_projects, deleted_projects)
            # puts "new_specs:#{new_specs}".send(:red)
            return new_specs
        end

        def showMergeLog(added, updated, rollbacked, deleted)
            #31m: 红色 32m:绿色 33m:黄色 34m:蓝色
            #puts "\e[34m#{string}\e[0m"
            if added.any?
                puts "\n新增了以下项目:".send(:green)
                puts added.join("\n")
            end

            if updated.any?
                puts "\n更新了以下项目:". send(:yellow)
                puts updated.join("\n")
            end

            if rollbacked.any?
                puts "\n回滚了以下项目:".send(:red)
                puts rollbacked.join("\n")
            end

            if deleted.any?
                puts "\n移除了以下项目:".send(:red)
                puts deleted.join("\n")
            end

            unless added.any? || updated.any? || added.any? || deleted.any?
                puts "\n已经是最新版本".send(:green)
            end
        end
    end
end