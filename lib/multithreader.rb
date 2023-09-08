# frozen_string_literal: true

class Multithreader
  class << self
    def call(max_threads=1, &block)
      loop { block.call }
    end
  end
end
