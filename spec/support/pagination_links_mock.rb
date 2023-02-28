# frozen_string_literal: true

module PaginationLinksMock
  def page_links(to_page, rel_type)
    page_info = "page=#{to_page}"
    "<http://www.example.com/api/projects?#{page_info}>; rel=\"#{rel_type}\""
  end
end
