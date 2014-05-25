# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  remember_created_at :datetime
#  sign_in_count       :integer          default(0), not null
#  current_sign_in_at  :datetime
#  last_sign_in_at     :datetime
#  current_sign_in_ip  :string(255)
#  last_sign_in_ip     :string(255)
#  uid                 :string(255)      not null
#  name                :string(255)
#  password            :string(255)
#  email               :string(255)      default("")
#  image_path          :string(255)      default("")
#  token               :string(255)      not null
#  refresh_token       :string(255)      not null
#  expires_at          :datetime
#  expires             :boolean
#  admin               :boolean          default(FALSE)
#  created_at          :datetime
#  updated_at          :datetime
#

class User < ActiveRecord::Base
  validates :name, presence: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :trackable, :validatable
  devise :rememberable, :trackable, :omniauthable

  alias_attribute :admin?, :admin

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    user = User.where(:uid => access_token["uid"]).first

    info = access_token["info"]
    cred = access_token["credentials"]
    columns = {
      name:       info["name"],
      email:      info["email"],
      image_path: info["image"],
      password:   Devise.friendly_token[0,20],
      token:      cred["token"],
      expires_at: Time.at(cred["expires_at"]),
      expires:    cred["expires"]
    }

    refresh_token = cred["refresh_token"]
    columns[:refresh_token] = refresh_token if refresh_token

    if user
      user.update_attributes(columns)
    else
      columns[:uid] = access_token["uid"]
      user = User.create(columns)
    end
    user
  end
end
