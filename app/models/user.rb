# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[line] # for line-login

  has_many :diaries, dependent: :destroy
  has_one :buff, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :like_diaries, through: :likes, source: :diary

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

  def own?(object)
    object.user_id == id
  end

  def like(diary)
    like = Like.find_or_create_by!(user_id: id, diary_id: diary.id)
    like.count += diary.user.buff.sum_buff
    like.save!
  end
end
