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

require 'spec_helper'

describe User do
  before { @user = FactoryGirl.create(:user) }

  subject { @user }

  it { should respond_to(:id) }
  it { should respond_to(:remember_created_at) }
  it { should respond_to(:sign_in_count) }
  it { should respond_to(:current_sign_in_at) }
  it { should respond_to(:last_sign_in_at) }
  it { should respond_to(:current_sign_in_ip) }
  it { should respond_to(:last_sign_in_ip) }
  it { should respond_to(:password) }
  it { should respond_to(:uid) }
  it { should respond_to(:name) }
  it { should respond_to(:password) }
  it { should respond_to(:email) }
  it { should respond_to(:image_path) }
  it { should respond_to(:token) }
  it { should respond_to(:refresh_token) }
  it { should respond_to(:expires_at) }
  it { should respond_to(:expires) }
  it { should respond_to(:admin?) }

  it { should be_valid }

  describe "without name" do
    before { @user.name = " " }
    it { should be_invalid }
  end

  describe "about find_for_google_oauth2" do
    let(:uid) { random_string(15) }
    let(:name) { "yunotti_#{random_string}" }
    let(:access_token) { JSON.parse(generate_access_token(uid, name)) }
    before { @user = User.find_for_google_oauth2(access_token) }

    it { should_not be_nil }
    its(:name) { should eq name }
    its(:email) { should eq "yunotti@hidamari.com" }
    its(:image_path) { should eq sprintf("https://lh3.googleusercontent.com/%s/photo.jpg?sz=50", uid) }
    its(:password) { should_not be_empty }
    its(:token) { should_not be_empty }
    its(:refresh_token) { should_not be_empty }
    its(:expires_at) { should_not be_nil }
    its(:admin?) { should_not be_true }

    describe "after changing your name on google, reauthenticate user" do
      let(:other_name) { "changed_yunotti_#{random_string}" }
      before do
        other_token = JSON.parse(generate_access_token(uid, other_name))
        @same_user = User.find_for_google_oauth2(other_token)
      end

      subject { @same_user }

      its(:email) { should eq "yunotti@hidamari.com" }
      its(:name) { should eq other_name }
    end
  end
end

def generate_access_token(uid, name)
  "{\"provider\" : \"google\", \"uid\" : \"#{uid}\", \"info\" :  {\"name\" : \"#{name}\",   \"email\" : \"yunotti@hidamari.com\",   \"first_name\" : \"yuno\",   \"last_name\" : \"tti\",   \"image\" :    \"https://lh3.googleusercontent.com/#{uid}/photo.jpg?sz=50\",   \"urls\" : {\"Google\" : \"https://plus.google.com/#{uid}\"}}, \"credentials\" :  {\"token\" :    \"tokentokentokentokentokentokentokentokenegageagae\",   \"refresh_token\" : \"refreshtokenrefreferefefeefarrareafae\",   \"expires_at\" : 1400894677,   \"expires\" : true}, \"extra\" :  {\"id_token\" :    \"hoge\",   \"raw_info\" :    {\"kind\" : \"plus#personOpenIdConnect\",     \"sub\" : \"#{uid}\",     \"name\" : \"#{name}\",     \"given_name\" : \"yuno\",     \"family_name\" : \"tti\",     \"profile\" : \"https://plus.google.com/#{uid}\",     \"picture\" :      \"https:https://lh3.googleusercontent.com/#{uid}/photo.jpg?sz=50\",     \"email\" : \"#{name}@hidamari.com\",     \"email_verified\" : \"true\",     \"locale\" : \"en\"}}}"
end
