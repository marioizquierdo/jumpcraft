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
    it "load only medium maps if those are the only available maps" do
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
  end

  describe "GET #near_score" do
    before do
      @user = create :user, score: 1500
      sign_in @user
    end

    it "responds successfully with an HTTP 200 status code" do
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
