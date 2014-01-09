describe Game do
  describe "last_played_map_ids" do
  	before do
      @user = create :user
      @m1 = build :map
      @m2 = build :map
      @m3 = build :map
      @g1 = create :game, user: @user, map: @m1
      @g2 = create :game, user: @user, map: @m2
      @g3 = create :game, user: @user, map: @m3
  	end

    it "returns the last played maps in desc order" do
      ids = Game.last_played_map_ids(@user, 10)
      ids.should == [@m3, @m2, @m1].map(&:id)
    end

    it "has a limit" do
      ids = Game.last_played_map_ids(@user, 2)
      ids.should == [@m3, @m2].map(&:id)
    end

    it "does not include other people's games" do
      @u2 = create :user
      @m4 = build :map
      @g4 = create :game, user: @u2, map: @m4
      ids = Game.last_played_map_ids(@user, 10)
      ids.should include(@m1.id)
      ids.should_not include(@m4.id)
    end
  end

end