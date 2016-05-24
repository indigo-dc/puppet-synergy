require 'spec_helper'
describe 'synergy' do

  context 'with defaults for all parameters' do
    it { should contain_class('synergy') }
  end
end
