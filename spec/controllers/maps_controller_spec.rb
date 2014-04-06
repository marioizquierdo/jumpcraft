require 'spec_helper'

describe MapsController do

  describe "GET #ladder" do
    it "responds successfully with an HTTP 200 status code" do
      get :ladder
      expect(response.status).to eq(200)
    end

    it "loads maps into @maps" do
      map1, map2 = create(:map), create(:map)
      get :ladder
      expect(assigns(:maps)).to match_array([map1, map2])
    end

    it "orders by score DESC" do
      @creator = create :user
      @map1, @map3, @map2 = create(:map, score: 1, creator: @creator), create(:map, score: 3, creator: @creator), create(:map, score: 2, creator: @creator)
      get :ladder
      expect(assigns(:maps)).to match_array([@map1, @map3, @map2])
    end
  end

  describe "GET #suggestions" do
    before do
      @user = create :user, score: 1500
      sign_in @user
    end
    it "responds successfully with an HTTP 200 status code" do
      get :suggestions, format: 'json'
      expect(response.status).to eq(200)
    end
    it "loads up to three map suggestions" do
      create :map, score: 1000
      create :map, score: 1500
      create :map, score: 1600
      create :map, score: 1700
      get :suggestions, format: 'json'
      maps = assigns(:maps)
      maps.should have(3).elements
    end
    it "loads only one suggestion if that's the only available one" do
      create :map, score: 1500
      get :suggestions, format: 'json'
      maps = assigns(:maps)
      maps.should have(1).elements
    end
    it "loads only medium maps if those are the only available maps" do
      create :map, score: @user.score # with user score, the difficulty should be medium
      create :map, score: @user.score
      create :map, score: @user.score
      get :suggestions, format: 'json'
      maps = assigns(:maps)
      maps.should have(3).elements
      maps.each do |map|
        map.dificulty_relative_to(@user.score).should == :medium
      end
    end
    context "if didnt play the trial games" do
      it "only suggests trial maps" do
        @m1 = create :map, score: @user.score, creator_id: User::INFILTRATION_USER_ID
        @m2 = create :map, score: @user.score

        get :suggestions, format: 'json'
        maps = assigns(:maps)
        maps.should have(1).element
        maps.first.should == @m1
      end
    end
    context "after playing the trial games" do
      before do
        stub_const("User::TRIAL_GAMES_BEFORE_REGULAR_SUGGESTIONS", 0)
      end

      it "excludes own user maps" do
        @m1 = create :map, score: @user.score
        @m2 = create :map, score: @user.score, creator: @user
        get :suggestions, format: 'json'
        maps = assigns(:maps)
        maps.should have(1).element
        maps.first.should == @m1
      end
      it "excludes previosly played maps" do
        @m1 = create :map, score: @user.score
        @m2 = create :map, score: @user.score
        create :game, user: @user, map: @m2 # user played map @m2
        get :suggestions, format: 'json'
        maps = assigns(:maps)
        maps.should have(1).element
        maps.first.should == @m1
      end
      it "does not exclude own user maps or previosly played maps if those are the only ones available" do
        @m1 = create :map, score: @user.score
        @m2 = create :map, score: @user.score
        @m3 = create :map, score: @user.score, creator: @user # own map
        create :game, user: @user, map: @m1 # user played map @m1
        create :game, user: @user, map: @m2 # user played map @m2
        get :suggestions, format: 'json'
        maps = assigns(:maps)
        maps.should have(3).elements
        maps.should include @m1
        maps.should include @m2
        maps.should include @m3
      end
    end
    it "should not return maps that are too hard or too easy" do
      @m1 = create :map, score: @user.score
      @m2 = create :map, score: @user.score + 10*Map::DIFFICULTY_RANGE # too hard
      @m3 = create :map, score: @user.score - 10*Map::DIFFICULTY_RANGE # too easy
      get :suggestions, format: 'json'
      maps = assigns(:maps)
      maps.should have(1).element
      maps.first.should == @m1
    end
    it "returns same suggestions if called multiple times" do
      6.times{ create :map, score: @user.score }
      get :suggestions, format: 'json'
      maps = assigns(:maps)
      maps.should have(3).elements

      get :suggestions, format: 'json'
      maps2 = assigns(:maps)
      maps2.should == maps

      get :suggestions, format: 'json'
      maps3 = assigns(:maps)
      maps3.should == maps
    end
    it "retries new suggestions if previously there were no suggestions" do
      get :suggestions, format: 'json'
      maps = assigns(:maps)
      maps.should have(0).elements

      3.times{ create :map, score: @user.score }
      get :suggestions, format: 'json'
      maps = assigns(:maps)
      maps.should have(3).elements
    end
    it "returns new suggestions after finishing a game" do
      4.times{ create :map, score: @user.score }
      get :suggestions, format: 'json'
      maps = assigns(:maps)
      maps.should have(3).elements

      # user plays one of the suggested maps
      game = create :game, user: @user.reload, map: maps[0], finished: false
      game.finish_and_save! # will invalidate the cached suggestions on the user
      sign_out @user; sign_in @user; # have to do this in order to reload the mocked current_user from DB

      get :suggestions, format: 'json'
      maps2 = assigns(:maps)
      maps2.should_not == maps
    end
  end

  describe "GET #near_score" do
    before do
      @user = create :user, score: 1500
      sign_in @user
    end

    it "responds successfully with an HTTP 200 status code" do
      create :map # ensure map collection exists, needed to perform the mapreduce in get_plays_count_for with no errors

      get :near_score, format: 'json'
      expect(response.status).to eq(200)
    end

    it "loads up to 50 maps into @maps, ordered by score, of with half below the current_user score" do
      52.times do |i|
        diff = i - 26
        create :map, score: @user.score + diff
      end

      get :near_score, format: 'json'
      maps = assigns(:maps)
      maps.size.should == 50
      under_score = @user.score - 26
      over_score = @user.score + 24
      maps.first.score.should == under_score
      maps.last.score.should == over_score

      maps.select{|m| m.score < @user.score}.size.should == 25
      maps.select{|m| m.score == @user.score }.size.should == 1
      maps.select{|m| m.score > @user.score}.size.should == 24
    end
    context "rendered json" do
      render_views
      it "includes played_by_current_user in the generated map json, with the number of times user played the map" do
        create :map, score: @user.score
        get :near_score, format: 'json'
        map = assigns(:maps).first
        json = response.body
        maps_data_list = JSON.parse(json)['maps']
        map_data = maps_data_list.first
        map_data['played_by_current_user'].should == 0
      end

      it "includes played_by_current_user properly if the player did play the map before" do
        map = create :map, score: @user.score
        Game.create user: @user, map: map, finished: true # 1
        Game.create user: @user, map: map, finished: true # 2
        get :near_score, format: 'json'
        map = assigns(:maps).first
        json = response.body
        maps_data_list = JSON.parse(json)['maps']
        map_data = maps_data_list.first
        map_data['played_by_current_user'].should == 2
      end
    end
  end

end
