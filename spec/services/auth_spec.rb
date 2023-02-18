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
end

