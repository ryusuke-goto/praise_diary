# frozen_string_literal: true

class MissionsController < ApplicationController
  before_action :authenticate_user!, only: %i[show]
  ## 設定したprepare_meta_tagsをprivateにあってもpostコントローラー以外にも使えるようにする
  helper_method :prepare_meta_tags

  def show
    case params[:type]
    when 'daily'
      @missions = current_user.my_dailies.order(id: :asc)
      @mission_status = current_user.user_dailies.index_by(&:daily_mission_id)
      render partial: 'shared/daily_missions', locals: { daily_missions: @missions, daily_status: @mission_status }
    when 'challenge'
      @missions = current_user.my_challenges.order(id: :asc)
      @mission_status = current_user.user_challenges.index_by(&:challenge_mission_id)
      render partial: 'shared/challenge_missions',
             locals: { challenge_missions: @missions, challenge_status: @mission_status }
    else
      render plain: 'Invalid mission type', status: :bad_request
    end
  end
end
