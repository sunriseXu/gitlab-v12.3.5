# frozen_string_literal: true

require 'spec_helper'

describe EE::UsageStatistics do
  describe '.distinct_count_by' do
    let(:user_1) { create(:user) }
    let(:user_2) { create(:user) }

    context 'two records created by the same user' do
      let!(:models_created_by_user_1) { create_list(:group_member, 2, user: user_1)}

      it 'returns a count of 1' do
        expect(::GroupMember.distinct_count_by(:user_id)).to eq(1)
      end
    end

    context 'one record created by each user' do
      let!(:model_created_by_user_1) { create(:group_member, user: user_1)}
      let!(:model_created_by_user_2) { create(:group_member, user: user_2)}

      it 'returns a count of 2' do
        expect(::GroupMember.distinct_count_by(:user_id)).to eq(2)
      end
    end

    context 'the count query times out' do
      before do
        allow_any_instance_of(ActiveRecord::Relation)
          .to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))
      end

      it 'does not raise an error' do
        expect { ::GroupMember.distinct_count_by(:user_id) }.not_to raise_error
      end

      it 'returns -1' do
        expect(::GroupMember.distinct_count_by(:user_id)).to eq(-1)
      end
    end
  end
end
