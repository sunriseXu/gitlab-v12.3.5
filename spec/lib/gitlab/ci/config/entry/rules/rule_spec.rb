require 'fast_spec_helper'
require 'gitlab_chronic_duration'
require 'support/helpers/stub_feature_flags'
require_dependency 'active_model'

describe Gitlab::Ci::Config::Entry::Rules::Rule do
  let(:entry) { described_class.new(config) }

  describe '.new' do
    subject { entry }

    context 'with a when: value but no clauses' do
      let(:config) { { when: 'manual' } }

      it { is_expected.to be_valid }
    end

    context 'when specifying an if: clause' do
      let(:config) { { if: '$THIS || $THAT', when: 'manual' } }

      it { is_expected.to be_valid }

      describe '#when' do
        subject { entry.when }

        it { is_expected.to eq('manual') }
      end
    end

    context 'using a list of multiple expressions' do
      let(:config) { { if: ['$MY_VAR == "this"', '$YOUR_VAR == "that"'] } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid format' do
        expect(subject.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when specifying an invalid if: clause expression' do
      let(:config) { { if: ['$MY_VAR =='] } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid statement' do
        expect(subject.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when specifying an if: clause expression with an invalid token' do
      let(:config) { { if: ['$MY_VAR == 123'] } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid statement' do
        expect(subject.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when using invalid regex in an if: clause' do
      let(:config) { { if: ['$MY_VAR =~ /some ( thing/'] } }

      it 'reports an error about invalid expression' do
        expect(subject.errors).to include(/invalid expression syntax/)
      end
    end

    context 'when using an if: clause with lookahead regex character "?"' do
      let(:config) { { if: '$CI_COMMIT_REF =~ /^(?!master).+/' } }

      context 'when allow_unsafe_ruby_regexp is disabled' do
        it { is_expected.not_to be_valid }

        it 'reports an error about invalid expression syntax' do
          expect(subject.errors).to include(/invalid expression syntax/)
        end
      end
    end

    context 'when using a changes: clause' do
      let(:config) { { changes: %w[app/ lib/ spec/ other/* paths/**/*.rb] } }

      it { is_expected.to be_valid }
    end

    context 'when using a string as an invalid changes: clause' do
      let(:config) { { changes: 'a regular string' } }

      it { is_expected.not_to be_valid }

      it 'reports an error about invalid policy' do
        expect(subject.errors).to include(/should be an array of strings/)
      end
    end

    context 'when using a list as an invalid changes: clause' do
      let(:config) { { changes: [1, 2] } }

      it { is_expected.not_to be_valid }

      it 'returns errors' do
        expect(subject.errors).to include(/changes should be an array of strings/)
      end
    end

    context 'specifying a delayed job' do
      let(:config) { { if: '$THIS || $THAT', when: 'delayed', start_in: '15 minutes' } }

      it { is_expected.to be_valid }

      it 'sets attributes for the job delay' do
        expect(entry.when).to eq('delayed')
        expect(entry.start_in).to eq('15 minutes')
      end

      context 'without a when: key' do
        let(:config) { { if: '$THIS || $THAT', start_in: '15 minutes' } }

        it { is_expected.not_to be_valid }

        it 'returns an error about the disallowed key' do
          expect(entry.errors).to include(/disallowed keys: start_in/)
        end
      end

      context 'without a start_in: key' do
        let(:config) { { if: '$THIS || $THAT', when: 'delayed' } }

        it { is_expected.not_to be_valid }

        it 'returns an error about tstart_in being blank' do
          expect(entry.errors).to include(/start in can't be blank/)
        end
      end
    end

    context 'when specifying unknown policy' do
      let(:config) { { invalid: :something } }

      it { is_expected.not_to be_valid }

      it 'returns error about invalid key' do
        expect(entry.errors).to include(/unknown keys: invalid/)
      end
    end

    context 'when clause is empty' do
      let(:config) { {} }

      it { is_expected.not_to be_valid }

      it 'is not a valid configuration' do
        expect(entry.errors).to include(/can't be blank/)
      end
    end

    context 'when policy strategy does not match' do
      let(:config) { 'string strategy' }

      it { is_expected.not_to be_valid }

      it 'returns information about errors' do
        expect(entry.errors)
          .to include(/should be a hash/)
      end
    end
  end

  describe '#value' do
    subject { entry.value }

    context 'when specifying an if: clause' do
      let(:config) { { if: '$THIS || $THAT', when: 'manual' } }

      it 'stores the expression as "if"' do
        expect(subject).to eq(if: '$THIS || $THAT', when: 'manual')
      end
    end

    context 'when using a changes: clause' do
      let(:config) { { changes: %w[app/ lib/ spec/ other/* paths/**/*.rb] } }

      it { is_expected.to eq(config) }
    end

    context 'when default value has been provided' do
      let(:config) { { changes: %w[app/**/*.rb] } }

      before do
        entry.default = { changes: %w[**/*] }
      end

      it 'does not set a default value' do
        expect(entry.default).to eq(nil)
      end

      it 'does not add to provided configuration' do
        expect(entry.value).to eq(config)
      end
    end
  end

  describe '.default' do
    it 'does not have default value' do
      expect(described_class.default).to be_nil
    end
  end
end
