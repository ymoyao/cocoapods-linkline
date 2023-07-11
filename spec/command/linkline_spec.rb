require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Linkline do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ linkline }).should.be.instance_of Command::Linkline
      end
    end
  end
end

