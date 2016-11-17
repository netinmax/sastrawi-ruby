require 'confix_stripping/precedence_adjustment_specification'

module Sastrawi
  module Stemmer
    module Context
      class Context
        def initialize(original_word, current_word, dictionary, visitor_provider)
            @original_word = original_word
            @current_word = current_word
            @dictionary = dictionary
            @visitor_provider = visitor_provider
            @process_is_stopped = false
            @removals = []
            @visitors = []
            @suffix_visitors = []
            @prefix_visitors = []
            @result = ''

            self.init_visitors
        end

        def init_visitors
          @visitors = visitor_provider.get_visitor
          @suffix_visitors = visitor_provider.get_suffix_visitor
          @prefix_visitors = visitor_provider.get_prefix_visitor
        end

        def stop_process
          @process_is_stopped = true
        end

        def add_removal(removal)
          @removals = removal
        end

        def execute
          self.start_stemming_process

          if @dictionary.include?(@current_word)
            @result = @current_word
          else
            @result = original_word
          end
        end

        def start_stemming_process
          return if @dictionary.include?(@current_word)

          self.accept_visitors(@visitors)

          return if @dictionary.include?(@current_word)

          cs_precendence_adjustment_specification = PrecedenceAdjustmentSpecification.new

          if cs_precendence_adjustment_specification.is_satisfied_by(@original_word)
            self.remove_prefixes
            return if @dictionary.include?(@current_word)

            self.remove_suffixes
            if @dictionary.include?(@current_word)
              return
            else
              @current_word = @original_word)
              @removals = []
            end

            self.remove_suffixes
            return if @dictionary.include?(@current_word)

            self.remove_prefixes
            return if @dictionary.include?(@current_word)

            self.loop_last_return
          end
        end

        def loop_last_return
          self.restore_prefix

          removals = @removals
          reversed_removals = removals.reverse
          current_word = @current_word

          reversed_removals.each do |reverse_removal|
            next if !self.suffix_removal(reverse_removal)

            if reverse_removal.get_removed_part == 'kan'
              @current_word = reverse_removal.get_result << 'k'

              self.remove_prefixes
              return if @dictionary.include?(@current_word)

              @current_word = reverse_removal.get_result << 'kan'
            else
              @current_word = reverse_removal.get_subject
            end

            self.remove_prefixes
            return if @dictionary.include?(@current_word)

            @removals = removals
            @current_word = current_word
          end
        end

        def remove_prefixes
          3.times do
            self.accept_prefix_visitors(@prefix_visitors)
            return if @dictionary.include?(@current_word)
          end
        end

        def remove_suffixes
          self.accept_visitors(@suffix_visitors)
        end

        def accept(visitor)
          visitor.visit(self)
        end

        def accept_visitors(visitors = [])
          visitors.each do |visitor|
            self.accept(visitor)

            return @current_word if @dictionary.include?(@current_word)

            return @current_word if @process_is_stopped
          end
        end

        def accept_prefix_visitors(visitors = [])
          removal_length = @removals.length

          visitors.each do |visitor|
            self.accept(visitor)

            return @current_word if @dictionary.include?(@current_word)

            return @current_word if @process_is_stopped

            return if @removals.length > removal_length
          end
        end

        def suffix_removal?(removal)
          return removal.get_affix_type == 'DS'
            || removal.get_affix_type == 'PP'
            || removal.get_affix_type == 'P'
        end

        def restore_prefix
          @removals.each do |removal|
            if removal.get_affix_type == 'DP'
              @current_word = removal.get_subject
              break
            end
          end

          @removals.each do |removal|
            if removal.get_affix_type == 'DP'
              @removals.delete(r)
            end
          end
        end
      end
    end
  end
end
