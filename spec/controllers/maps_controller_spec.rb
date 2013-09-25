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
      get :suggestions
      expect(response.status).to eq(200)
    end
    it "loads up to three map suggestions" do
      create :map, score: 1000
      create :map, score: 1500
      create :map, score: 1600
      create :map, score: 1700
      get :suggestions
      maps = assigns(:maps)
      maps.should have(3).suggestions
    end
    it "loads only one suggestion if that's the only available one" do
      create :map, score: 1500
      get :suggestions
      maps = assigns(:maps)
      maps.should have(1).suggestions
    end
    it "load only medium maps if those are the only available maps" do
      create :map, score: @user.score # with user score, the difficulty should be medium
      create :map, score: @user.score
      create :map, score: @user.score
      get :suggestions
      maps = assigns(:maps)
      maps.each do |suggestion|
        suggestion[0].should == :medium
      end
    end
  end

  describe "GET #near_score" do
    before do
      @user = create :user, score: 1500
      sign_in @user
    end

    it "responds successfully with an HTTP 200 status code" do
      get :near_score
      expect(response.status).to eq(200)
    end

    it "loads up to 50 maps into @maps, ordered by score, of with half below the current_user score" do
      52.times do |i|
        diff = i - 26
        create :map, score: @user.score + diff
      end

      get :near_score
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
  end

end
