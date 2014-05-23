# == Schema Information
#
# Table name: pages
#
#  id           :integer          not null, primary key
#  url          :string(255)
#  is_exist     :boolean          default(FALSE)
#  extracted_at :datetime
#  created_at   :datetime
#  updated_at   :datetime
#

require 'spec_helper'

describe Page do
  before do
    @page = FactoryGirl.create(:page)
  end

  subject { @page }

  it { should respond_to(:url) }
  it { should respond_to(:is_exist) }
  it { should respond_to(:exist?) }
  it { should respond_to(:extracted_at) }
  it { should respond_to(:add_videos!) }
  it { should respond_to(:valid_videos) }

  it { should be_valid }

  describe "invalid case" do
    describe "when url is empty" do
      before { @page.url = " " }
      it { should_not be_valid }
    end
  end

  describe "video associations" do
    describe "after add multiple videos" do
      let(:videos) { (1..3).map {|n| FactoryGirl.create(:video)} }
      before { @page.add_videos!(videos) }

      its(:videos) { should eq videos }
    end

    describe "valid_videos" do
      describe "with available video" do
        let(:video) { FactoryGirl.create(:video) }
        before { @page.add_videos!([video]) }

        its(:valid_videos) { should eq [video] }
      end

      describe "with unexist video" do
        before do
          video = FactoryGirl.create(:video, is_exist: false)
          @page.add_videos!([video])
        end

        its(:valid_videos) { should be_empty }
      end

      describe "with unembed video" do
        before do
          video = FactoryGirl.create(:video, is_embed: false)
          @page.add_videos!([video])
        end

        its(:valid_videos) { should be_empty }
      end

      describe "with not auto play video" do
        before do
          video = FactoryGirl.create(:video, can_auto_play: false)
          @page.add_videos!([video])
        end

        its(:valid_videos) { should be_empty }
      end
    end
  end
end
