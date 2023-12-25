# frozen_string_literal: true

class HistoricalDataWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    return if License.current.nil? || License.current&.trial?

    HistoricalData.track!
  end
end
