require 'spec_helper'

describe Map do

  describe "dificulty_relative_to(user_skill)" do
    let(:map) { build :map, skill_deviation: 2 }
    let(:user_skill) { 25 }
    [:trivial, :very_easy, :easy, :medium, :hard, :very_hard, :impossible].each do |difficulty|
      it "returns :#{difficulty}" do
        map.skill_mean = skill_relative_to(user_skill, difficulty)
        val = map.dificulty_relative_to(user_skill)
        expect(val).to eq(difficulty)
      end
    end
    it "returns :unknown if the map.skill_deviation is too hight" do
      map.skill_deviation = 1
      map.skill_mean = user_skill
      expect(map.dificulty_relative_to(user_skill)).to eq(:medium)

      map.skill_deviation = 6
      expect(map.dificulty_relative_to(user_skill)).to eq(:unknown)
    end
  end

  describe ".find_near_dificulty" do
    let(:user_skill) { 25 }
    [:easy, :medium, :hard].each do |difficulty|
      it "returns :#{difficulty} maps" do
        map = create :map, skill_mean: skill_relative_to(user_skill, difficulty)
        expect(map.dificulty_relative_to(user_skill)).to eq(difficulty)
        expect(Map.find_near_dificulty(user_skill, difficulty)).to eq(map)
      end
    end
    it "finds other maps if can not find the desired difficulty" do
      map = create :map, skill_mean: skill_relative_to(user_skill, :very_hard)
      expect(Map.find_near_dificulty(user_skill, :easy)).to eq(map) # still find the very_hard one because it's the only one in DB

      map4 = create :map, skill_mean: skill_relative_to(user_skill, :easy)
      expect(Map.find_near_dificulty(user_skill, :easy)).to eq(map4) # prefer to find the closest one
    end
    it "finds a random map inside the scoped difficulty" do
      map1 = create :map, skill_mean: skill_relative_to(user_skill, :medium)
      map2 = create :map, skill_mean: skill_relative_to(user_skill, :medium)

      # it should eventually find the two maps
      map = Map.find_near_dificulty(user_skill, :medium)
      new_map = map
      while new_map == map
        new_map = Map.find_near_dificulty(user_skill, :medium)
      end
      expect(new_map).to_not eq(map)
    end
    it "finds a random map inside the scoped difficulty also on the difficulties around the desired difficulty" do
      map1 = create :map, skill_mean: skill_relative_to(user_skill, :easy)
      map2 = create :map, skill_mean: skill_relative_to(user_skill, :hard)

      # it should eventually find the two maps
      map = Map.find_near_dificulty(user_skill, :medium)
      new_map = map
      while new_map == map
        new_map = Map.find_near_dificulty(user_skill, :medium)
      end
      expect(new_map).to_not eq(map)
    end

    it "filters out the :exclude list of maps" do
      map = create :map, skill_mean: skill_relative_to(user_skill, :easy)
      expect(Map.find_near_dificulty(user_skill, :easy, exclude: [map])).to eq(nil)

      map2 = create :map, skill_mean: skill_relative_to(user_skill, :easy)
      expect(Map.find_near_dificulty(user_skill, :easy, exclude: [map])).to eq(map2)
      expect(Map.find_near_dificulty(user_skill, :easy, exclude: [map, map2])).to eq(nil)
      expect(Map.find_near_dificulty(user_skill, :easy, exclude: [map, nil, map2])).to eq(nil)
    end
  end


  describe ".find_random_within_skill" do
    let(:low_skill) { 20 }
    let(:upp_skill) { 30 }
    context "with maps in that skill range" do
      before do
        # within range
        @m1 = create :map, skill_mean: low_skill
        @m2 = create :map, skill_mean: (low_skill + upp_skill) / 2
        @m3 = create :map, skill_mean: upp_skill

        # outside range
        @m4 = create :map, skill_mean: upp_skill + 1
        @m5 = create :map, skill_mean: low_skill - 1
      end
      it "returns one random map with the desired range" do
        5.times do # try several times because the result is random
          map = Map.find_random_within_skill(low_skill, upp_skill)
          expect(map).to_not eq(nil)
          expect(map.skill_mean).to be <= upp_skill
          expect(map.skill_mean).to be >= low_skill
        end
      end
      it "finds a random map" do
        map = Map.find_random_within_skill(low_skill, upp_skill)
        new_map = map

        # it should eventually find a different one
        while new_map == map
          new_map = Map.find_random_within_skill(low_skill, upp_skill)
        end
        expect(new_map).to_not eq(map)
      end
      context "with :exclude option" do
        it "exludes those maps" do
          3.times do # try several times because the result is random
            map = Map.find_random_within_skill(low_skill, upp_skill, exclude: [@m1, @m2])
            expect(map).to eq(@m3) # this is the only one left under scope
          end
        end
        it "accepts maps, ids and nil values" do
          3.times do # try several times because the result is random
            map = Map.find_random_within_skill(low_skill, upp_skill, exclude: [@m1.id, nil, @m2])
            expect(map).to eq(@m3) # this is the only one left under scope
          end
        end
      end
      context "with :scope option" do
        before do
          # create a map within range that has specific name, to test the scope
          @map = create :map, skill_mean: low_skill+1, name: 'target map yupi yupi'
          @scope = ->(criteria){ criteria.where(name: 'target map yupi yupi') }
        end
        it "filters the maps based on that scope" do
          3.times do # try several times because the result is random
            map = Map.find_random_within_skill(low_skill, upp_skill, scope: @scope)
            expect(map).to eq(@map)
          end
        end
        it "works nicely with :exclude option" do
          3.times do # try several times because the result is random
            map = Map.find_random_within_skill(low_skill, upp_skill, scope: @scope, exclude: [@m1, @m2])
            expect(map).to eq(@map)
          end
          map = Map.find_random_within_skill(low_skill, upp_skill, scope: @scope, exclude: [@map])
          expect(map).to eq(nil)
        end
      end
    end
    context "with no maps within skill range" do
      before do
        # outside range
        create :map, skill_mean: upp_skill + 1
        create :map, skill_mean: low_skill - 1
      end
      it "returns nil" do
        map = Map.find_random_within_skill(low_skill, upp_skill)
        expect(map).to eq(nil)
      end
    end
    it "finds maps with skill == upper_skill" do
      create :map, skill_mean: upp_skill
      map = Map.find_random_within_skill(low_skill, upp_skill)
      expect(map).to_not eq(nil)
    end
    it "finds maps with skill == lower_skill" do
      create :map, skill_mean: low_skill
      map = Map.find_random_within_skill(low_skill, upp_skill)
      expect(map).to_not eq(nil)
    end
  end
end

# helper function
def skill_relative_to(user_skill, difficulty)
  user_skill + Map.lower_skill_treshold_for(difficulty) + 0.1
end