require 'spec_helper'

describe Spree::Zone do

  #context 'factory' do
    #let(:zone) { Spree::Zone.create :name => "FooZone" }
    #it "should set zone members correctly" do
      #zone.zone_members.count.should == 1
    #end
  #end

  context "#destroy" do
    let(:zone) { Spree::Zone.create :name => "FooZone" }

    it "should destroy all zone members" do
      zone.destroy
      zone.zone_members.count.should == 0
    end
  end

  context "#match" do
    let(:country_zone) { Spree::Zone.create :name => "CountryZone" }
    let(:country) { Factory :country }

    before { country_zone.members.create(:zoneable => country) }

    context "when there is only one qualifying zone" do
      let(:address) { Factory(:address, :country => country) }

      it "should return the qualifying zone" do
        Spree::Zone.match(address).should == country_zone
      end
    end

    context "when there are two qualified zones with same member type" do
      let(:address) { Factory(:address, :country => country) }
      let(:second_zone) { Spree::Zone.create :name => "SecondZone" }

      before { second_zone.members.create(:zoneable => country) }
      it "should return the zone that was created first" do
        Spree::Zone.match(address).should == country_zone
      end
    end

    context "when there are two qualified zones with different member types" do
      let(:state_zone) { Spree::Zone.create :name => "StateZone" }
      let(:state) { Factory :state }
      let(:address) { Factory(:address, :country => country, :state => state) }

      before { state_zone.members.create(:zoneable => state) }

      it "should return the zone with the more specific member type" do
        Spree::Zone.match(address).should == state_zone
      end
    end

    context "when there are no qualifying zones" do
      it "should return nil" do
        Spree::Zone.match(Spree::Address.new).should be_nil
      end
    end
  end

end
