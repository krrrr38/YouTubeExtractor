require 'spec_helper'

describe Users::OmniauthCallbacksController do
  before { @controller = Users::OmniauthCallbacksController.new }

  subject { @controller }

  it { should respond_to(:google) }
end
