require 'piculet/dsl/permission'

module Piculet
  class DSL
    class EC2
      class SecurityGroup
        class Permissions
          attr_reader :result

          def initialize(security_group, direction, &block)
            @security_group = security_group
            @direction = direction
            @result = {}
            instance_eval(&block)
          end

          private
          def permission(protocol, port_range = nil, &block)
            if port_range and not port_range.kind_of?(Range)
              raise TypeError, "SecurityGroup `#{@security_group}`: #{@direction}: can't convert #{port_range} into Range"
            end

            key = [protocol, port_range]

            if @result.has_key?(key)
              raise "SecurityGroup `#{@security_group}`: #{@direction}: #{key} is already defined"
            end

            @result[key] = Permission.new(@security_group, @direction, key, &block).result
          end
        end # Permissions
      end # SecurityGroup
    end # EC2
  end # DSL
end # Piculet
