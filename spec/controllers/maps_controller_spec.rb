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
      @user = create :user, skill_mean: 25
      sign_in @user
    end

    context "before finishing the trial games" do
      it "responds successfully with an HTTP 200 status code" do
        get :suggestions, params: { format: 'json' }
        expect(response.status).to eq(200)
      end
      it "uses get_trial_suggestions to get initial trial maps" do
        @m_no_trial = create :map, name: 'San Francisco' # Not a Trial, this should not be used

        allow($stdout).to receive(:write) # silence puts
        require 'rake'
        Jumpcraft::Application.load_tasks
        Rake::Task['trial_maps:create'].invoke # create trial maps
        allow($stdout).to receive(:write).and_call_original # restore puts

        # last_played.size == 0
        expect(Game.last_played_map_ids(@user, 20).size).to eq(0)
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
        expect(maps.map(&:name)).to include('San Francisco', 'The Bunker', 'Caravel Ships')

        # last_played.size == 1
        played_map = maps[0]
        play_and_finish_game(@user, played_map) # user plays one of the maps
        expect(Game.last_played_map_ids(@user, 20).size).to eq(1)
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
        expect(maps.map(&:name)).to_not include(played_map.name)

        # last_played.size == 2
        played_map = maps[1]
        play_and_finish_game(@user, played_map) # user plays one of the maps
        expect(Game.last_played_map_ids(@user, 20).size).to eq(2)
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.map(&:name)).to_not include(played_map.name)

        # last_played.size == 3
        played_map = maps[2]
        play_and_finish_game(@user, played_map) # user plays one of the maps
        expect(Game.last_played_map_ids(@user, 20).size).to eq(3)
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
        expect(maps.map(&:name)).to_not include(played_map.name)

        # last_played.size == 4
        played_map = maps[1]
        play_and_finish_game(@user, played_map) # user plays one of the maps
        expect(Game.last_played_map_ids(@user, 20).size).to eq(4)
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
        expect(maps.map(&:name)).to_not include(played_map.name)

        # last_played.size == 5
        played_map = maps[0]
        play_and_finish_game(@user, played_map) # user plays one of the maps
        expect(Game.last_played_map_ids(@user, 20).size).to eq(5)
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
        expect(maps.map(&:name)).to_not include(played_map.name)

        # last_played.size == 6
        played_map = maps[1]
        play_and_finish_game(@user, played_map) # user plays one of the maps
        expect(Game.last_played_map_ids(@user, 20).size).to eq(6)
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
        expect(maps.map(&:name)).to_not include(played_map.name)
      end
    end
    context "after playing the trial games" do
      before do
        allow_any_instance_of(MapsController).to receive(:get_trial_suggestions).and_return(nil)
      end

      it "responds successfully with an HTTP 200 status code" do
        get :suggestions, params: { format: 'json' }
        expect(response.status).to eq(200)
      end
      it "loads up to three map suggestions" do
        create :map, skill_mean: 24
        create :map, skill_mean: 25
        create :map, skill_mean: 26
        create :map, skill_mean: 26
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
      end
      it "loads only one suggestion if that's the only available one" do
        create :map, skill_mean: 25
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(1)
      end
      it "loads only medium maps if those are the only available maps" do
        create :map, skill_mean: @user.skill_mean
        create :map, skill_mean: @user.skill_mean
        create :map, skill_mean: @user.skill_mean
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
        maps.each do |map|
          expect(@user.difficulty_of_playing(map)).to eq(:medium)
        end
      end
      it "excludes own user maps" do
        @m1 = create :map, skill_mean: @user.skill_mean
        @m2 = create :map, skill_mean: @user.skill_mean, creator: @user
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(1)
        expect(maps.first).to eq(@m1)
      end
      it "excludes previosly played maps" do
        @m1 = create :map, skill_mean: @user.skill_mean
        @m2 = create :map, skill_mean: @user.skill_mean
        create :game, user: @user, map: @m2 # user played map @m2
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(1)
        expect(maps.first).to eq(@m1)
      end
      it "does not exclude own user maps or previosly played maps if those are the only ones available" do
        @m1 = create :map, skill_mean: @user.skill_mean
        @m2 = create :map, skill_mean: @user.skill_mean
        @m3 = create :map, skill_mean: @user.skill_mean, creator: @user # own map
        create :game, user: @user, map: @m1 # user played map @m1
        create :game, user: @user, map: @m2 # user played map @m2
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
        expect(maps).to include @m1
        expect(maps).to include @m2
        expect(maps).to include @m3
      end
      it "should not return maps that are too hard or too easy" do
        @m1 = create :map, skill_mean: @user.skill_mean
        @m2 = create :map, skill_mean: @user.skill_mean + 22*Map::DIFFICULTY_RANGE # too hard
        @m3 = create :map, skill_mean: @user.skill_mean - 22*Map::DIFFICULTY_RANGE # too easy
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(1)
        expect(maps.first).to eq(@m1)
      end
      it "returns same suggestions if called multiple times" do
        6.times{ create :map, skill_mean: @user.skill_mean }
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)

        get :suggestions, params: { format: 'json' }
        maps2 = assigns(:maps)
        expect(maps2).to eq(maps)

        get :suggestions, params: { format: 'json' }
        maps3 = assigns(:maps)
        expect(maps3).to eq(maps)
      end
      it "retries new suggestions if previously there were no suggestions" do
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(0)

        3.times{ create :map, skill_mean: @user.skill_mean }
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)
      end
      it "returns new suggestions after finishing a game" do
        4.times{ create :map, skill_mean: @user.skill_mean }
        get :suggestions, params: { format: 'json' }
        maps = assigns(:maps)
        expect(maps.size).to eq(3)

        # user plays one of the suggested maps
        play_and_finish_game(@user, maps[0])

        get :suggestions, params: { format: 'json' }
        maps_after = assigns(:maps)
        expect(maps_after).to_not eq(maps)
      end
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
      expect(maps.size).to eq(50)
      under_score = @user.score - 26
      over_score = @user.score + 24
      expect(maps.first.score).to eq(under_score)
      expect(maps.last.score).to eq(over_score)

      expect(maps.select{|m| m.score < @user.score}.size).to eq(25)
      expect(maps.select{|m| m.score == @user.score }.size).to eq(1)
      expect(maps.select{|m| m.score > @user.score}.size).to eq(24)
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
        expect(map_data['played_by_current_user']).to eq(0)
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
        expect(map_data['played_by_current_user']).to eq(2)
      end
    end
  end

end

# helper function
def skill_relative_to(user_skill, difficulty)
  user_skill + Map.lower_skill_treshold_for(difficulty) + 0.1
end

# Play a map and finish game
def play_and_finish_game(user, map)
  game = create :game, user: user.reload, map: map, finished: false
  game.finish_and_save! # will invalidate the cached suggestions on the user
  sign_out user; sign_in user; # have to do this in order to reload the mocked current_user from DB
end
