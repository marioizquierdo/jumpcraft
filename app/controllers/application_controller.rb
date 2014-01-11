class ApplicationController < ActionController::Base
  # protect_from_forgery # skip csrf token verification to make more easy to login from Flash


private

  # Calculate the @offset used for Mongoid skip from params[:page] and @page_size
  # Note: set @page_size before if you don't want to use default page size
  def offset_from_page_param
    page = view_context.current_page
    page_size = @page_size || 100
    (page - 1) * page_size
  end
end
