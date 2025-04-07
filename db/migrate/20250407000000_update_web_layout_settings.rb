class UpdateWebLayoutSettings < ActiveRecord::Migration[6.1]
  def up
    # 获取所有启用了高级布局的用户
    User.where('settings @> ?', '{"web.advanced_layout": true}').find_each do |user|
      # 将他们的布局设置为 'advanced'
      settings = user.settings
      settings['web.layout'] = 'advanced'
      settings.delete('web.advanced_layout')
      user.update_column(:settings, settings)
    end

    # 将其他所有用户的默认布局设置为 'classic'
    User.where('settings @> ?', '{"web.advanced_layout": false}').or(User.where('settings ? :key = false', key: 'web.advanced_layout')).find_each do |user|
      settings = user.settings
      settings['web.layout'] = 'classic'
      settings.delete('web.advanced_layout')
      user.update_column(:settings, settings)
    end
  end

  def down
    # 恢复到旧设置
    User.where('settings @> ?', '{"web.layout": "advanced"}').find_each do |user|
      settings = user.settings
      settings['web.advanced_layout'] = true
      settings.delete('web.layout')
      user.update_column(:settings, settings)
    end

    User.where('settings @> ?', '{"web.layout": "classic"}').or(User.where('settings @> ?', '{"web.layout": "two_column"}')).find_each do |user|
      settings = user.settings
      settings['web.advanced_layout'] = false
      settings.delete('web.layout')
      user.update_column(:settings, settings)
    end
  end
end
