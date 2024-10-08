# frozen_string_literal: true

class DailyMission < ApplicationRecord
  has_many :user_dailies, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 65_535 }

  def self.check_record_user_dailies(user_id)
    # Create a user daily record corresponding to the newly added daily mission. Call this upon login.
    daily_mission_ids = pluck(:id)
    existing_daily_mission_ids = UserDaily.where(user_id:,
                                                 daily_mission_id: daily_mission_ids).pluck(:daily_mission_id)

    missing_daily_mission_ids = daily_mission_ids - existing_daily_mission_ids

    missing_daily_mission_ids.each do |daily_mission_id|
      UserDaily.create(user_id:, daily_mission_id:)
    end
  end

  def self.update_mission(user:, mission_title:)
    mission = find_by('title LIKE ?', "%#{mission_title}%")
    logger.debug "mission #{mission}"
    return { process: false, message: 'Mission not found' } unless mission

    user_daily = user.user_dailies.find_by(daily_mission_id: mission.id)
    logger.debug "user_daily #{user_daily.inspect}"
    if user_daily.present? && !user_daily.status
      logger.debug 'user_daily.update executed'
      user_daily.update(status: true)
      user.add_buff(daily: mission.buff)
      { process: true, message: mission.title }
    else
      logger.debug 'mission not found or user_challenge_status is already true'
      { process: false, message: 'Mission not found or already completed' }
    end
  end
end
