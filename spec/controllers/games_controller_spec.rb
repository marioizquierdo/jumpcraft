require 'spec_helper'

describe GamesController do

  before do
    @creator = create :user
    @map = create :map, creator: @creator
    @player = create :user
    sign_in @player
  end

  describe "POST #start" do
    context "with no user logged in" do
      before do
        sign_out @player
      end
      it "responds with error" do
        post :start, map_id: @map.id.to_s
        expect(response).not_to be_success
        expect(response.status).to eq(302) # redirect to login page
      end
    end

    context "with no map_id param" do
      it "responds with error" do
        expect {
          post :start
        }.to raise_error(Mongoid::Errors::InvalidFind)
      end
    end

    context "if a game was already in progress in the same map" do
      before do
        post :start, map_id: @map.id.to_s
        @game = Game.unfinished.first
      end
      it "responds with error" do
        post :start, map_id: @map.id.to_s
        expect(response).not_to be_success
        expect(response.status).to eq(403) # redirect to login page
      end
      it "finalizes the previous unfinished game" do
        post :start, map_id: @game.map.id.to_s
        @game.reload
        @game.should be_finished
        @game.map_defeated.should be_false
      end
    end

    context "if a game was already in progress in another map" do
      before do
        @other_map = create :map, creator: @creator
        post :start, map_id: @other_map.id.to_s
        @other_game = Game.unfinished.first
      end
      it "responds with error" do
        post :start, map_id: @map.id.to_s
        expect(response).not_to be_success
        expect(response.status).to eq(403) # redirect to login page
      end
    end

    it "creates a new unfinished map" do
      expect {
        post :start, map_id: @map.id.to_s
      }.to change{ Game.unfinished.count }.by(1)
    end
  end

  describe "POST #finish" do

    context "with no user logged in" do
      before do
        sign_out @player
      end
      it "respond with error" do
        post :finish
        expect(response).not_to be_success
        expect(response.status).to eq(302) # redirect to login page
      end
    end

    context "with no map_defeated param" do
      it "fails with a 403 error" do
        post :finish, collected_coins: 99
        expect(response.status).to eq(403)
        json = JSON.parse(response.body)
        json['error'].should == 'params map_defeated and collected_coins are mandatory'
      end
    end

    context "with no collected_coins param" do
      it "fails with a 403 error" do
        post :finish, map_defeated: 'true'
        expect(response.status).to eq(403)
        json = JSON.parse(response.body)
        json['error'].should == 'params map_defeated and collected_coins are mandatory'
      end
    end

    context "with no game in progress" do
      before do
        Game.unfinished.count.should == 0
      end
      it "responds with a 403 error" do
        post :finish, map_defeated: 'true', collected_coins: 99
        expect(response.status).to eq(403)
        json = JSON.parse(response.body)
        json['error'].should == 'Unfinished Game Not Found'
      end
    end

    context "with a game in progress" do
      before do
        post :start, map_id: @map.id.to_s
        @game = Game.unfinished.first
      end
      it "marks the game as finished" do
        post :finish, map_defeated: 'true', collected_coins: 99
        @game.reload.should be_finished
      end
      it "updates the player coins" do
        collected_coins = 99
        expect {
          post :finish, map_defeated: 'true', collected_coins: collected_coins
        }.to change{ @player.reload.coins }.by(collected_coins)
        @game.reload.coins.should == collected_coins
      end
      it "increments the played games for both the player and the map" do
        expect { expect {
          post :finish, map_defeated: 'true', collected_coins: 99
        }.to change{ @map.reload.played_games }.by(1)
        }.to change{ @player.reload.played_games }.by(1)
      end
      context "if the player wins" do
        it "updates the score of the map and the player" do
          @map.update_attribute(:score, 1000)
          @player.update_attribute(:score, 1000)

          post :finish, map_defeated: 'true', collected_coins: 99

          @player.reload.score.should > 1000
          @map.reload.score.should < 1000
        end
        it "increments player.won_games, but not map.won_games" do
          expect { expect {
            post :finish, map_defeated: 'true', collected_coins: 99
          }.to change{ @player.reload.won_games }.by(1)
          }.to_not change{ @map.reload.won_games }
        end
        it "records game.map_defeated = true" do
          post :finish, map_defeated: 'true', collected_coins: 99
          @game.reload.map_defeated.should be_true
        end
      end
      context "if the player loses" do
        it "updates the score of the map and the player" do
          @map.update_attribute(:score, 1000)
          @player.update_attribute(:score, 1000)

          post :finish, map_defeated: 'false', collected_coins: 99

          @player.reload.score.should < 1000
          @map.reload.score.should > 1000
        end
        it "increments map.won_games, but not player.won_games" do
          expect { expect {
            post :finish, map_defeated: 'false', collected_coins: 99
          }.to change{ @map.reload.won_games }.by(1)
          }.to_not change{ @player.reload.won_games }
        end
        it "records game.map_defeated = false" do
          post :finish, map_defeated: 'false', collected_coins: 99
          @game.reload.map_defeated.should be_false
        end
      end
    end
  end

end
