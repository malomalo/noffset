require 'active_record'
require "action_controller"

module Noffset
  module Relation

    def paginate(hash=nil)
      @noffset = if hash.nil?
        { terminal: nil, anchor: nil, surplus: false }
      elsif anchor = hash[:after] || hash['after']
        { terminal: :after, anchor: anchor, surplus: false }
      elsif anchor = hash[:before] || hash['before']
        { terminal: :before, anchor: anchor, surplus: false }
      else
        { terminal: nil, anchor: nil, surplus: false }
      end
      
      self
    end
    
    def next_page?
      if @noffset[:terminal] == :before
        true
      else
        load
        @noffset[:surplus]
      end
    end
    
    def next_params
      load
      {
        after: @noffset[:order].map { |k, d| [k, @records.last.send(k)] }.to_h,
        order: @noffset[:order]
      }
    end
    
    def prev_page?
      if @noffset[:terminal] == :after
        true
      elsif @noffset[:terminal].nil?
        false
      else
        load
        @noffset[:surplus]
      end
    end
    
    def prev_params
      load
      {
        before: @noffset[:order].map { |k, d| [k, @records.first.send(k)] }.to_h,
        order: @noffset[:order]
      }
    end

    def to_sql
      add_pagination_predicate
      super
    end
    
    def load(&block)
      return self if loaded?
      
      add_pagination_predicate
      
      super
      
      if instance_variable_defined?(:@noffset) && @noffset
        @records = @records.dup
        
        if @records.length > @noffset[:limit]
          @records.pop
          @noffset[:surplus] = true
        end

        @records.reverse! if @noffset[:inverse]
        
        @records.freeze
      end
      
      self
    end

    def add_pagination_predicate
      return if !instance_variable_defined?(:@noffset) || @noffset.nil? || @noffset[:compiled]
      @noffset[:compiled] = true
      @noffset[:order] = {}
      order_values.each do |order|
        @noffset[:order][order.expr.name.to_sym] = order.direction
      end
        
      @noffset[:limit] = limit_value || 100
      self.limit_value = @noffset[:limit] + 1

      if @noffset[:anchor]
        
        conditions = nil
        columns_visited = nil
        self.order_values.each do |order|
          if conditions.nil?
            conditions = if (@noffset[:terminal] == :after && order.ascending?) || (@noffset[:terminal] == :before && order.descending?)
              Arel::Nodes::Grouping.new(table[order.expr.name].gt(@noffset[:anchor][order.expr.name.to_s]))
            else
              Arel::Nodes::Grouping.new(table[order.expr.name].lt(@noffset[:anchor][order.expr.name.to_s]))
            end
            columns_visited = table[order.expr.name].eq(@noffset[:anchor][order.expr.name.to_s])
          else
            conditions = if (@noffset[:terminal] == :after && order.ascending?) || (@noffset[:terminal] == :before && order.descending?)
              conditions.or(Arel::Nodes::Grouping.new(columns_visited.and(table[order.expr.name].gt(@noffset[:anchor][order.expr.name.to_s]))))
            else
              conditions.or(Arel::Nodes::Grouping.new(columns_visited.and(table[order.expr.name].lt(@noffset[:anchor][order.expr.name.to_s]))))
            end
            columns_visited = columns_visited.and(table[order.expr.name].eq(@noffset[:anchor][order.expr.name.to_s]))
          end
        end
        
        if @noffset[:terminal] == :before
          @noffset[:inverse] = true
          order_values.map!(&:reverse)
        end

        where!(conditions)
      end
      
    end

  end
end

ActiveRecord::Relation.prepend(Noffset::Relation)
ActiveRecord::Querying.delegate :paginate, to: :all

module Noffset
  module Helpers
    
    def next_page_path(scope)
      if scope.next_page?
        params = request.query_parameters.dup
        params.delete(:before)
        request.path + '?' + params.merge(scope.next_params).to_param
      end
    end
    alias :next_page :next_page_path
    
    def next_page_url(scope)
      if scope.next_page?
        request.base_url + next_page_path(scope)
      end
    end
    
    def previous_page_path(scope)
      if scope.prev_page?
        params = request.query_parameters.dup
        params.delete(:after)
        request.path + '?' + params.merge(scope.prev_params).to_param
      end
    end
    alias :prev_page_path :previous_page_path
    alias :prev_page :previous_page_path
    alias :previous_page :previous_page_path
    
    def previous_page_url(scope)
      if scope.prev_page?
        request.base_url + prev_page_path(scope)
      end
    end
    alias :prev_page_url :previous_page_url
    
  end
end


::ActionController::Base.send :include, Noffset::Helpers
::ActionController::Base.helper_method :next_page_path, :next_page, :next_page_url
::ActionController::Base.helper_method :prev_page_path, :prev_page, :prev_page_url
::ActionController::Base.helper_method :previous_page_path, :previous_page, :previous_page_url
