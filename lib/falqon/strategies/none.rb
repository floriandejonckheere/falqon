# frozen_string_literal: true

# typed: true

module Falqon
  module Strategies
    ##
    # Retry strategy that does not retry
    #
    class None < Strategy
      sig { params(entry: Entry).void }
      def retry(entry)
        # Kill message immediately
        entry.kill

        # Remove identifier from processing queue
        queue.processing.remove(entry.id)
      end
    end
  end
end
