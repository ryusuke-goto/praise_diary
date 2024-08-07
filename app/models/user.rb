# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[line] # for line-login

  has_many :diaries, dependent: :destroy
  has_one :buff, dependent: :destroy
  has_one :reward, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :like_diaries, through: :likes, source: :diary
  has_many :user_dailies, dependent: :destroy
  has_many :user_challenges, dependent: :destroy
  has_many :my_dailies, through: :user_dailies, source: :daily_mission
  has_many :my_challenges, through: :user_challenges, source: :challenge_mission

  after_create :create_buff, :create_reward
  after_commit :ensure_buff_exists, :ensure_reward_exists,on: :create

  # for line-login
  def social_profile(provider)
    social_profiles.select { |sp| sp.provider == provider.to_s }.first
  end

  def set_values(omniauth)
    return if provider.to_s != omniauth['provider'].to_s || uid != omniauth['uid']

    credentials = omniauth['credentials']
    info = omniauth['info']

    credentials['refresh_token']
    credentials['secret']
    credentials.to_json
    info['name']
    # self.set_values_by_raw_info(omniauth['extra']['raw_info'])
  end

  def set_values_by_raw_info(raw_info)
    self.raw_info = raw_info.to_json
    save!
  end

  def create_buff
    self.create_buff!
  end

  def ensure_buff_exists
    self.buff || self.create_buff!
  end

  def create_reward
    self.create_reward!
  end

  def ensure_reward_exists
    self.reward || self.create_reward!
  end

  def own?(object)
    object.user_id == id
  end

  def like(diary)
    like = Like.find_or_create_by!(user_id: id, diary_id: diary.id)
    like.count += diary.user.buff.sum_buff
    like.save!
  end

  def liked_diary_count
    counts = self.likes.count
    if counts > 10
      result = ChallengeMission.update_mission(user: self, mission_title: "10個の日記にいいね")
      if result
        { success: true, message: "10個の日記にいいね" }
      else
        logger.debug "message::::like_count not update"
        { success: false }
      end
    else
      logger.debug "message::::like_count not update"
      { success: false }
    end
  end

  def add_buff(daily: 0, challenge: 0, mission: nil)
    logger.debug "message::::add_buff executed"
    current_buff = self.buff
    if daily > 0
      current_buff.daily_buff += daily
      logger.debug "message::::daily_buff: #{current_buff.daily_buff}"
      current_buff.save!
      current_buff.sum_buff += current_buff.daily_buff
      current_buff.save!
      return true
    elsif challenge > 0
      current_buff.challenge_buff += challenge
      logger.debug "message::::challenge_buff: #{current_buff.challenge_buff}"    
      current_buff.save!
      current_buff.sum_buff += current_buff.challenge_buff
      current_buff.save!
      result = self.update_reward(mission)
      logger.debug "message::::update_reward result #{result}"
      return true
    else
      logger.debug "error::::cannot add buff"
      return false
    end
    
  end

  def update_reward(mission)
    logger.debug "message::::update_reward executed"
    logger.debug "message::::mission is #{mission.inspect}"
    reward = self.reward
    if mission.like_css.present?
      reward.like_css += mission.like_css
      logger.debug "message::::like_css update"
    end
    if mission.diary_css.present?
      reward.diary_css += mission.diary_css
      logger.debug "message::::diary_css update"
    end
    if mission.theme_css.present?
      reward.theme_css += mission.theme_css
      logger.debug "message::::theme_css update"
    end
    
  end
end
