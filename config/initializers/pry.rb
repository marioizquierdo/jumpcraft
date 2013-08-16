if Rails.env.development?
  Infiltration::Application.configure do
    # Use Pry instead of IRB
    silence_warnings do
      begin
        require 'pry'
        IRB = Pry
      rescue LoadError
      end
    end
  end
end