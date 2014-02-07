require 'spec_helper'

describe Map do

  describe "dificulty_relative_to(user_score)" do
    let(:map) { build :map }
    let(:user_score) { 2000 }
    it "returns :trivial" do
      map.score = 1000
      map.dificulty_relative_to(user_score).should == :trivial
    end
    it "returns :very_easy" do
      map.score = 1950
      map.dificulty_relative_to(user_score).should == :very_easy
    end
    it "returns :easy" do
      map.score = 1975
      map.dificulty_relative_to(user_score).should == :easy
    end
    it "returns :medium" do
      map.score = 2000
      map.dificulty_relative_to(user_score).should == :medium
    end
    it "returns :hard" do
      map.score = 2025
      map.dificulty_relative_to(user_score).should == :hard
    end
    it "returns :very_hard" do
      map.score = 2050
      map.dificulty_relative_to(user_score).should == :very_hard
    end
    it "returns :impossible" do
      map.score = 3000
      map.dificulty_relative_to(user_score).should == :impossible
    end
  end

  describe ".find_near_dificulty" do
    let(:user_score) { 2000 }
    it "returns :easy maps" do
      map = create :map, score: user_score - Map::DIFFICULTY_RANGE
      map.dificulty_relative_to(user_score).should == :easy
      Map.find_near_dificulty(user_score, :easy).should == map
    end
    it "returns :medium maps" do
      map = create :map, score: user_score + 1
      map.dificulty_relative_to(user_score).should == :medium
      Map.find_near_dificulty(user_score, :medium).should == map
    end
    it "returns :hard maps" do
      map = create :map, score: user_score + Map::DIFFICULTY_RANGE
      map.dificulty_relative_to(user_score).should == :hard
      Map.find_near_dificulty(user_score, :hard).should == map
    end
    it "finds other maps if can not find the desired difficulty" do
      map = create :map, score: user_score + 4*Map::DIFFICULTY_RANGE
      map.dificulty_relative_to(user_score).should == :impossible
      Map.find_near_dificulty(user_score, :easy).should == map # still find the very_hard one because it's the only one in DB

      map2 = create :map, score: user_score + Map::DIFFICULTY_RANGE
      map2.dificulty_relative_to(user_score).should == :hard
      Map.find_near_dificulty(user_score, :easy).should == map2 # prefer to find the closest one

      map3 = create :map, score: user_score
      map3.dificulty_relative_to(user_score).should == :medium
      Map.find_near_dificulty(user_score, :easy).should == map3 # prefer to find the closest one

      map4 = create :map, score: user_score - Map::DIFFICULTY_RANGE
      map4.dificulty_relative_to(user_score).should == :easy
      Map.find_near_dificulty(user_score, :easy).should == map4 # prefer to find the exact match
    end
    it "finds a random map inside the scoped difficulty" do
      map1 = create :map, score: user_score
      map1.dificulty_relative_to(user_score).should == :medium
      map2 = create :map, score: user_score
      map2.dificulty_relative_to(user_score).should == :medium

      # it should eventually find the two maps
      map = Map.find_near_dificulty(user_score, :medium)
      new_map = map
      while new_map == map
        new_map = Map.find_near_dificulty(user_score, :medium)
      end
      new_map.should_not == map
    end
    it "finds a random map inside the scoped difficulty also on the difficulties around the desired difficulty" do
      map1 = create :map, score: user_score - Map::DIFFICULTY_RANGE
      map1.dificulty_relative_to(user_score).should == :easy

      map2 = create :map, score: user_score + Map::DIFFICULTY_RANGE
      map2.dificulty_relative_to(user_score).should == :hard

      # it should eventually find the two maps
      map = Map.find_near_dificulty(user_score, :medium)
      new_map = map
      while new_map == map
        new_map = Map.find_near_dificulty(user_score, :medium)
      end
      new_map.should_not == map
    end

    it "filters out the :exclude list of maps" do
      map = create :map, score: user_score - Map::DIFFICULTY_RANGE
      map.dificulty_relative_to(user_score).should == :easy
      Map.find_near_dificulty(user_score, :easy, exclude: [map]).should be_nil

      map2 = create :map, score: user_score - Map::DIFFICULTY_RANGE
      map2.dificulty_relative_to(user_score).should == :easy
      Map.find_near_dificulty(user_score, :easy, exclude: [map]).should == map2
      Map.find_near_dificulty(user_score, :easy, exclude: [map, map2]).should be_nil
      Map.find_near_dificulty(user_score, :easy, exclude: [map, nil, map2]).should be_nil
    end
  end


  describe ".find_random_within_score" do
    let(:low_score) { 100 }
    let(:upp_score) { 200 }
    context "with maps in that score range" do
      before do
        # within range
        @m1 = create :map, score: low_score
        @m2 = create :map, score: (low_score + upp_score) / 2
        @m3 = create :map, score: upp_score

        # outside range
        @m4 = create :map, score: upp_score + 1
        @m5 = create :map, score: low_score - 1
      end
      it "returns one random map with the desired range" do
        5.times do # try several times because the result is random
          map = Map.find_random_within_score(low_score, upp_score)
          map.should_not be_nil
          map.score.should be <= upp_score
          map.score.should be >= low_score
        end
      end
      it "finds a random map" do
        map = Map.find_random_within_score(low_score, upp_score)
        new_map = map

        # it should eventually find a different one
        while new_map == map
          new_map = Map.find_random_within_score(low_score, upp_score)
        end
        new_map.should_not == map
      end
      context "with :exclude option" do
        it "exludes those maps" do
          3.times do # try several times because the result is random
            map = Map.find_random_within_score(low_score, upp_score, exclude: [@m1, @m2])
            map.should == @m3 # this is the only one left under scope
          end
        end
        it "accepts maps, ids and nil values" do
          3.times do # try several times because the result is random
            map = Map.find_random_within_score(low_score, upp_score, exclude: [@m1.id, nil, @m2])
            map.should == @m3 # this is the only one left under scope
          end
        end
      end
      context "with :scope option" do
        before do
          # create a map within range that has specific name, to test the scope
          @map = create :map, score: low_score+1, name: 'target map yupi yupi'
          @scope = ->(criteria){ criteria.where(name: 'target map yupi yupi') }
        end
        it "filters the maps based on that scope" do
          3.times do # try several times because the result is random
            map = Map.find_random_within_score(low_score, upp_score, scope: @scope)
            map.should == @map
          end
        end
        it "works nicely with :exclude option" do
          3.times do # try several times because the result is random
            map = Map.find_random_within_score(low_score, upp_score, scope: @scope, exclude: [@m1, @m2])
            map.should == @map
          end
          map = Map.find_random_within_score(low_score, upp_score, scope: @scope, exclude: [@map])
          map.should == nil
        end
      end
    end
    context "with no maps within score range" do
      before do
        # outside range
        create :map, score: upp_score + 1
        create :map, score: low_score - 1
      end
      it "returns nil" do
        map = Map.find_random_within_score(low_score, upp_score)
        map.should be_nil
      end
    end
    it "finds maps with score == upper_score" do
      create :map, score: upp_score
      map = Map.find_random_within_score(low_score, upp_score)
      map.should_not be_nil
    end
    it "finds maps with score == lower_score" do
      create :map, score: low_score
      map = Map.find_random_within_score(low_score, upp_score)
      map.should_not be_nil
    end
  end


end