describe Map do

  describe ".find_random_within_score" do
    let(:low_score) { 100 }
    let(:upp_score) { 200 }
    context "with maps in that score range" do
      before do
        # within range
        create :map, score: low_score
        create :map, score: (low_score + upp_score) / 2
        create :map, score: upp_score

        # outside range
        create :map, score: upp_score + 1
        create :map, score: low_score - 1
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