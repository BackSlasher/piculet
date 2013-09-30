$: << File.expand_path("#{File.dirname __FILE__}/../lib")
$: << File.expand_path("#{File.dirname __FILE__}/../spec")

require 'rubygems'
require 'piculet'
require 'spec_helper'

describe Piculet::Client do
  before(:each) {
    groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
    }

    @ec2 = AWS::EC2.new
  }

  after(:all) do
    groupfile { (<<-EOS)
ec2 TEST_VPC_ID do
  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
    }
  end

  [:ingress, :egress].each do |direction|
    [[:tcp, 80..81], [:udp, 53..54], [:any, nil], [:icmp, -1..-1]].each do |protocol, port_range|
      context "delete #{protocol} #{direction} permission allow from ip ranges and groups" do #
        before do
          groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"
  end

  security_group "default" do
    description "default VPC security group"

    #{direction} do
      permission #{protocol.inspect}, #{port_range.inspect} do
        ip_ranges(
          "0.0.0.0/0",
          "127.0.0.1/32"
        )
        groups(
          "default",
          "any_other_security_group"
        )
      end # permission
    end # ingress
  end # security_group
end # ec2
EOS
          }
        end

        it do
          groupfile { (<<EOS)
ec2 TEST_VPC_ID do
  security_group "any_other_security_group" do
    description "any other security group"
  end

  security_group "default" do
    description "default VPC security group"
  end # security_group
end # ec2
EOS
          }

          exported = export_security_groups
          expect(exported.keys).to eq([TEST_VPC_ID])

          expect(exported[TEST_VPC_ID]).to eq([[
            [:description , "any other security group"],
            [:egress      , EMPTY_ARRAY],
            [:ingress     , EMPTY_ARRAY],
            [:name        , "any_other_security_group"],
            [:owner_id    , TEST_OWNER_ID],
          ],[
            [:description , "default VPC security group"],
            [:egress      , EMPTY_ARRAY],
            [:ingress     , EMPTY_ARRAY],
            [:name        , "default"],
            [:owner_id    , TEST_OWNER_ID],
          ]])
        end # it
      end # context ##################################################
    end # each #######################################################
  end # each #########################################################
end # default
