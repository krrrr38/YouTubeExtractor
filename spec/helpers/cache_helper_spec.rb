require 'spec_helper'

class DummyHelper
  include CacheHelper
end

describe CacheHelper do
  let (:helper) { DummyHelper.new }
  subject { helper }

  it { should respond_to(:generate_cache_key) }
end
