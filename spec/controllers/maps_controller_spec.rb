require 'spec_helper'

describe MapsController do

  describe "GET #index" do
    it "responds successfully with an HTTP 200 status code" do
      get :index
      expect(response).to be_success
      expect(response.status).to eq(200)
    end

    it "loads maps into @maps" do
      map1, map2 = create(:map), create(:map)
      get :index
      expect(assigns(:maps)).to match_array([map1, map2])
    end

    context "filtered by creator_id" do
      before do
        @creator = create :user
        @map1, @map2 = create(:map, creator: @creator), create(:map, creator: @creator)

        @otheruser = create :user
        @othermap = create :map, creator: @otheruser
      end
      it "loads only the maps created by that creator" do
        get :index, creator_id: @creator.id.to_s
        expect(assigns(:maps)).to match_array([@map1, @map2])
      end
    end
  end

  describe "POST #game" do
    before do
      @creator = create :user
      @map = create :map, creator: @creator
      @player = create :user
      sign_in @player
    end
    it "fails if user is not logged in" do
      sign_out @player
      post :game, id: @map.id.to_s
      expect(response).not_to be_success
      expect(response.status).to eq(302) # redirect to login page
    end
    context "with no map_defeated param" do
      it "fails with a 403 error" do
        post :game, id: @map.id.to_s, collected_coins: 99
        expect(response.status).to eq(403)
      end
    end
    context "with no collected_coins param" do
      it "fails with a 403 error" do
        post :game, id: @map.id.to_s, map_defeated: 'true'
        expect(response.status).to eq(403)
      end
    end
    it "creates a Game record" do
      expect {
        post :game, id: @map.id.to_s, map_defeated: 'true', collected_coins: 99
      }.to change{ Game.count }.by(1)
    end
    it "updates the player coins" do
      collected_coins = 99
      expect {
        post :game, id: @map.id.to_s, map_defeated: 'true', collected_coins: collected_coins
      }.to change{ @player.reload.coins }.by(collected_coins)
    end
    it "increments the played games for both the player and the map" do
      expect { expect {
        post :game, id: @map.id.to_s, map_defeated: 'true', collected_coins: 99
      }.to change{ @map.reload.played_games }.by(1)
      }.to change{ @player.reload.played_games }.by(1)
    end
    context "if the player wins" do
      it "updates the score of the map and the player" do
        @map.update_attribute(:score, 1000)
        @player.update_attribute(:score, 1000)

        post :game, id: @map.id.to_s, map_defeated: 'true', collected_coins: 99

        @player.reload.score.should > 1000
        @map.reload.score.should < 1000
      end
      it "increments player.won_games, but not map.won_games" do
        expect { expect {
          post :game, id: @map.id.to_s, map_defeated: 'true', collected_coins: 99
        }.to change{ @player.reload.won_games }.by(1)
        }.to_not change{ @map.reload.won_games }
      end
    end
    context "if the player loses" do
      it "updates the score of the map and the player" do
        @map.update_attribute(:score, 1000)
        @player.update_attribute(:score, 1000)

        post :game, id: @map.id.to_s, map_defeated: 'false', collected_coins: 99

        @player.reload.score.should < 1000
        @map.reload.score.should > 1000
      end
      it "increments map.won_games, but not player.won_games" do
        expect { expect {
          post :game, id: @map.id.to_s, map_defeated: 'false', collected_coins: 99
        }.to change{ @map.reload.won_games }.by(1)
        }.to_not change{ @player.reload.won_games }
      end
    end
  end

end
