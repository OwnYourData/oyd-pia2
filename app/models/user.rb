# == Schema Information
#
# Table name: users
#
#  id                       :bigint(8)        not null, primary key
#  email                    :string           default(""), not null
#  encrypted_password       :string           default(""), not null
#  reset_password_token     :string
#  reset_password_sent_at   :datetime
#  remember_created_at      :datetime
#  sign_in_count            :integer          default(0), not null
#  current_sign_in_at       :datetime
#  last_sign_in_at          :datetime
#  current_sign_in_ip       :inet
#  last_sign_in_ip          :inet
#  confirmation_token       :string
#  confirmed_at             :datetime
#  confirmation_sent_at     :datetime
#  unconfirmed_email        :string
#  full_name                :string
#  language                 :string
#  frontend_url             :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  recovery_password_digest :string
#  password_key             :string
#  recovery_password_key    :string
#  email_notif              :boolean
#  assist_relax             :boolean
#  last_item_count          :integer
#  remember_digest          :string
#  reset_digest             :string
#  reset_sent_at            :datetime
#  app_nonce                :string
#  app_cipher               :string
#  phone_hash               :string
#  phone_key                :string
#  did                      :string
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class User < ApplicationRecord
	has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy
	has_many :repos, dependent: :destroy
	has_many :backups, dependent: :destroy
	has_many :logs, dependent: :destroy
	has_many :plugin_assists, dependent: :destroy

	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
			:recoverable, :rememberable, :trackable, :validatable, :confirmable

	attr_accessor :recovery_password, :recovery_password_confirmation, :remember_token

	before_save { self.email = email.downcase }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness:  { case_sensitive: false }

	def password_required?
		super if confirmed?
	end

	def password_match?
		self.errors[:password] << "can't be blank" if password.blank?
		self.errors[:recovery_password] << "can't be blank" if recovery_password.blank?
		self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
		self.errors[:recovery_password_confirmation] << "can't be blank" if recovery_password_confirmation.blank?
		self.errors[:recovery_password] << "shall not match password" if password == recovery_password
		self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
		self.errors[:recovery_password_confirmation] << "does not match recovery password" if recovery_password != recovery_password_confirmation
		password == password_confirmation && !password.blank? && recovery_password == recovery_password_confirmation && !recovery_password.blank? && password != recovery_password
	end

	def password_only_match?
		self.errors[:password] << "can't be blank" if password.blank?
		self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
		self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
		password == password_confirmation && !password.blank?
	end

	def User.digest(string)
		cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
													  BCrypt::Engine.cost
		BCrypt::Password.create(string, cost: cost)
	end

	def authenticated?(remember_token)
		BCrypt::Password.new(remember_digest).is_password?(remember_token)
	end
end
