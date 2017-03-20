require 'spec_helper'

describe Game do
  describe "last_played_map_ids" do
  	before do
      @user = create :user
  	end

    it "returns the last played maps" do
      ids = Game.last_played_map_ids(@user, 10)
      expect(ids).to eq([]) # no games yet

      @m1 = build :map
      @g1 = create :game, user: @user, map: @m1
      ids = Game.last_played_map_ids(@user, 10)
      expect(ids.size).to eq(1) # just one id
      expect(ids[0]).to eq(@m1.id)

      @m2 = build :map
      @g2 = create :game, user: @user, map: @m2
      ids = Game.last_played_map_ids(@user, 10)
      expect(ids).to eq([@m2, @m1].map(&:id)) # in desc order
    end

    it "has a limit" do
      3.times { create :game, user: @user }
      ids = Game.last_played_map_ids(@user, 2)
      expect(ids.size).to eq(2)
    end

    it "does not include other people's games" do
      @m1 = build :map
      @g1 = create :game, user: @user, map: @m1

      @u2 = create :user
      @m2 = build :map
      @g2 = create :game, user: @u2, map: @m2

      ids = Game.last_played_map_ids(@user, 10)
      expect(ids).to include(@m1.id)
      expect(ids).to_not include(@m2.id)
    end
  end

end