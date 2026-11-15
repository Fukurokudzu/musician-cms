require 'rails_helper'

RSpec.describe AuditEvent, type: :model do
  describe '.prune!' do
    after { Setting.audit_retention_days = 90 }

    it 'deletes entries older than the configured retention' do
      old_event = AuditEvent.create!(action: 'release.deleted', created_at: 100.days.ago)
      fresh_event = AuditEvent.create!(action: 'release.deleted')

      Setting.audit_retention_days = 90
      expect { AuditEvent.prune! }.to change { AuditEvent.count }.from(2).to(1)
      expect(AuditEvent.exists?(fresh_event.id)).to be(true)
      expect(AuditEvent.exists?(old_event.id)).to be(false)
    end

    it 'keeps everything when retention is 0' do
      AuditEvent.create!(action: 'release.deleted', created_at: 1000.days.ago)

      Setting.audit_retention_days = 0
      expect { AuditEvent.prune! }.not_to(change { AuditEvent.count })
    end
  end

  describe '.of_category' do
    it 'filters by action prefix' do
      AuditEvent.create!(action: 'auth.sign_in')
      AuditEvent.create!(action: 'release.uploaded')

      expect(AuditEvent.of_category('auth').pluck(:action)).to eq(['auth.sign_in'])
      expect(AuditEvent.of_category('bogus').count).to eq(2)
    end
  end
end
