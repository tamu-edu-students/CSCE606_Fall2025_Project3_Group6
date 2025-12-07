module ApplicationHelper
  def format_date(value)
    return nil if value.blank?

    date =
      if value.is_a?(String)
        begin
          Date.parse(value)
        rescue ArgumentError, TypeError
          nil
        end
      elsif value.respond_to?(:to_date)
        value.to_date
      end

    date&.strftime("%Y")
  end

  # Returns a data URI for a placeholder poster image
  # This ensures the placeholder always works in all environments (dev, test, CI, production)
  # without requiring asset precompilation
  def poster_placeholder_url
    # Use URL-encoded SVG data URI to avoid asset pipeline dependencies
    svg_content = '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="450"><rect fill="#333" width="300" height="450"/><text fill="#999" font-family="Arial" font-size="18" x="50%" y="50%" text-anchor="middle" dominant-baseline="middle">No Poster Available</text></svg>'
    "data:image/svg+xml;charset=utf-8,#{ERB::Util.url_encode(svg_content)}"
  end
end
