# This needs an `entity` object: Project or Group.
RSpec.shared_examples 'an entity with beta feature support' do
  context 'when license does not allow it' do
    before do
      stub_licensed_features(insights: false)
    end

    context 'when the feature flag is disabled globally' do
      before do
        stub_feature_flags(insights: false)
      end

      it { expect(entity.beta_feature_available?(:insights)).to be_falsy }
    end

    context 'when the feature flag is enabled globally' do
      before do
        stub_feature_flags(insights: true)
      end

      it { expect(entity.beta_feature_available?(:insights)).to be_truthy }
    end

    context 'when the feature flag is enabled for the entity' do
      before do
        stub_feature_flags(insights: { enabled: true, thing: entity })
      end

      it { expect(entity.beta_feature_available?(:insights)).to be_truthy }
    end
  end

  context 'when license allows it' do
    before do
      stub_licensed_features(insights: true)
    end

    context 'when the feature flag is disabled globally' do
      before do
        stub_feature_flags(insights: false)
      end

      it { expect(entity.beta_feature_available?(:insights)).to be_falsy }
    end

    context 'when the feature flag is enabled globally' do
      before do
        stub_feature_flags(insights: true)
      end

      it { expect(entity.beta_feature_available?(:insights)).to be_truthy }
    end

    context 'when the feature flag is enabled for the entity' do
      before do
        stub_feature_flags(insights: { enabled: true, thing: entity })
      end

      it { expect(entity.beta_feature_available?(:insights)).to be_truthy }
    end
  end
end
