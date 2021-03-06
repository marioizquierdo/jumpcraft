require 'spec_helper'

describe RatingSystem do

  describe "ladder_page_for_score" do
    it "returns the page that contains maps around that score" do

      # Create 5 pages with 2 maps each (last page only 1 map)
      # with scores from 200 to 160
      9.times do |i|
        create :map, score: 200 - 5*i
      end
      page_size = 2

      # # visualize map pages
      # total_pages = (Map.count.to_f / page_size).ceil
      # puts "--- Search #{Map.count} maps, page size #{page_size} (#{total_pages} pages)"
      # total_pages.times do |i|
      #   offset = i * page_size
      #   maps = Map.only(:score).desc(:score).skip(offset).limit(page_size)
      #   puts "page #{i + 1}: #{maps.to_a.map(&:score).join(', ')}"
      # end

      # left out of bounds
      score = 220
      expect(Map.where(score: score).first).to eq(nil)
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(1)

      # first element exact match
      score = 200
      expect(Map.where(score: score).first).to_not eq(nil)
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(1)

      # second element exact match
      score = 195
      expect(Map.where(score: score).first).to_not eq(nil)
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(1)

      # first page but without exact match
      score = 202
      expect(Map.where(score: score).first).to eq(nil)
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(1)

      # second page exact match
      score = 190
      expect(Map.where(score: score).first).to_not eq(nil)
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(2)

      # second page without exact match
      score = 188
      expect(Map.where(score: score).first).to eq(nil)
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(2)

      # middle page (3th) without exact match
      score = 178
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(3)

      # second to last page (4th) without exact match
      score = 166
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(4)

      # last page (5th) exact match
      score = 160
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(5)

      # right out of bounds
      score = 10
      page = RatingSystem.ladder_page_for_score(Map, score, page_size)
      expect(page).to eq(5)
    end
  end

end