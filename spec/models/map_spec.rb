describe Map do

  describe ".find_near_score" do
    let(:score) { 1000 }
    let(:distance) { 10 }
    context "with maps within score distance" do
      before do
        # within distance
        create :map, score: score
        create :map, score: score + distance - 1
        create :map, score: score - distance + 1

        # outside distance
        create :map, score: score - distance * 2
        create :map, score: score - distance * 2
      end
      it "returns one random map with the desired distance" do
        10.times do # try several times because the result is random
          map = Map.find_near_score(score, distance)
          map.should_not be_nil
          map.score.should be_within(distance).of(score)
        end
      end
    end
    context "with no maps within score distance" do
      before do
        # outside distance
        create :map, score: score - distance * 2
        create :map, score: score - distance * 2
      end
      it "returns nil" do
        map = Map.find_near_score(score, distance)
        map.should be_nil
      end
    end
    it "does not find maps with score == score + distance" do # score less than upper limit
      create :map, score: score + distance
      map = Map.find_near_score(score, distance)
      map.should be_nil
    end
    it "finds maps with score == score + distance - 1" do
      create :map, score: score + distance - 1
      map = Map.find_near_score(score, distance)
      map.should_not be_nil
    end
    it "finds maps with score == score - distance" do # score greather or equal than lower limit
      create :map, score: score - distance
      map = Map.find_near_score(score, distance)
      map.should_not be_nil
    end
  end

end