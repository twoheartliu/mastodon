# frozen_string_literal: true

class HomeController < ApplicationController
  include WebAppControllerConcern

  def index
    # 未登录用户访问根路径时，跳转到 nginx 托管的静态欢迎页
    return redirect_to('/overview', allow_other_host: false) if !user_signed_in? && request.path == root_path

    expires_in(15.seconds, public: true, stale_while_revalidate: 30.seconds, stale_if_error: 1.day) unless user_signed_in?
  end
end
