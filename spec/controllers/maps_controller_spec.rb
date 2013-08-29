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
    it "fails if user is not logged in" do
      post :game
      expect(response).not_to be_success
    end
    context "with "
  end

end
