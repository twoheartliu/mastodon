class UpdateWebLayoutSettings < ActiveRecord::Migration[6.1]
  def up
    # 确保 settings 列是 jsonb 类型
    column_type = connection.columns(:users).find { |c| c.name == 'settings' }.sql_type
    if column_type != 'jsonb'
      say "跳过迁移：settings 列不是 jsonb 类型"
      return
    end

    # 获取所有启用了高级布局的用户
    User.where("settings->>'web.advanced_layout' = 'true'").find_each do |user|
      # 将他们的布局设置为 'advanced'
      settings = user.settings || {}
      settings['web.layout'] = 'advanced'
      settings.delete('web.advanced_layout')
      user.update_column(:settings, settings)
    end

    # 将其他所有用户的默认布局设置为 'single-column'
    User.where("settings->>'web.advanced_layout' = 'false' OR settings->>'web.advanced_layout' IS NULL").find_each do |user|
      settings = user.settings || {}
      settings['web.layout'] = 'single-column'
      settings.delete('web.advanced_layout')
      user.update_column(:settings, settings)
    end
  end

  def down
    # 确保 settings 列是 jsonb 类型
    column_type = connection.columns(:users).find { |c| c.name == 'settings' }.sql_type
    if column_type != 'jsonb'
      say "跳过迁移：settings 列不是 jsonb 类型"
      return
    end

    # 恢复到旧设置
    User.where("settings->>'web.layout' = 'advanced'").find_each do |user|
      settings = user.settings || {}
      settings['web.advanced_layout'] = true
      settings.delete('web.layout')
      user.update_column(:settings, settings)
    end

    User.where("settings->>'web.layout' IN ('single-column', 'two_column')").find_each do |user|
      settings = user.settings || {}
      settings['web.advanced_layout'] = false
      settings.delete('web.layout')
      user.update_column(:settings, settings)
    end
  end
end
