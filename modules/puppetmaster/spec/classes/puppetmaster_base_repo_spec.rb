require_relative '../../../../rake_modules/spec_helper'

describe 'puppetmaster::base_repo' do
    let(:pre_condition) {
        """
        package { 'git': }
        """
    }
    it { should compile }
end
