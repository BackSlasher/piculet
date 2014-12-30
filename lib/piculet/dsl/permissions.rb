module Piculet
  class DSL
    class EC2
      class SecurityGroup
        class Permissions
          include Logger::ClientHelper
          def initialize(security_group, direction, &block)
            @security_group = security_group
            @direction = direction
            @result = {}
            instance_eval(&block)
          end

          def result
            @result.map do |key, perm|
              protocol, port_range = key

              OpenStruct.new({
                :protocol   => protocol,
                :port_range => port_range,
                :ip_ranges  => perm.ip_ranges,
                :groups     => perm.groups,
              })
            end
          end

          private
          def permission(protocol, port_range = nil, &block)
            if port_range and not port_range.kind_of?(Range)
              raise TypeError, "SecurityGroup `#{@security_group}`: #{@direction}: can't convert #{port_range} into Range"
            end

            key = [protocol, port_range]
            res = Permission.new(@security_group, @direction, key, &block).result

            if @result.has_key?(key)
              @result[key] = OpenStruct.new(@result[key].marshal_dump.merge(res.marshal_dump) {|key,old,new|
                log(:warn, "SecurityGroup `#{@security_group}`: #{@direction}: #{protocol}: #{port_range}: #{key}: #{old & new} are duplicated", :yellow) if (old & new).any?
                old|new
              })
	    else
              @result[key] = res
            end
          end
        end # Permissions
      end # SecurityGroup
    end # EC2
  end # DSL
end # Piculet
