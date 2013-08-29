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
  end

end
