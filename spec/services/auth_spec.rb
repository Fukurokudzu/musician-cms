require 'rails_helper'

RSpec.describe Auth, type: :model do
  describe 'Auth session service' do
    
    it "Returns valid hash for admin@admin / admin pair" do
      expect(Auth.new(Setting.admin_email, "admin").hashed_id).to be_instance_of(String)
    end
    
    it "Returns nil for wrong email" do
      expect(Auth.new("wrong@email", "admin").hashed_id).to be_nil
    end

    it "Returns nil for wrong pass" do
      expect(Auth.new(Setting.admin_email, "admin1").hashed_id).to be_nil
    end
    
  end

  describe '.change_password!' do
    it 'sets a new password that authenticates' do
      Auth.change_password!("new_secret")

      expect(Auth.new(Setting.admin_email, "new_secret").hashed_id).to be_instance_of(String)
    end

    it 'rejects blank passwords' do
      expect { Auth.change_password!("") }.to raise_error(ArgumentError)
    end
  end
end

